import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http ;
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/data/dummy_items.dart';
import 'package:shopping_list/models/category.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widget/new_item.dart';
class GroceryList extends StatefulWidget{
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List <GroceryItem> _groceryItems=[];
  String? _error;
  var _isLoading=true;

  @override
  void initState() {
    super.initState();
    _loadItem();
  }

  void _loadItem() async {
    final url=Uri.https('flutter-prep-b773f-default-rtdb.firebaseio.com','shopping-list.json');
    final response=await http.get(url);

    try{
      if(response.statusCode>=400){
        setState(() {
          _error='Failed to fetch the data,Please try again later.';
        });

      }
      if(response.body=='null'){
        setState(() {
          _isLoading=false;
        });
        return;
      }
      final Map<String,dynamic> listData=json.decode(response.body);
      final List<GroceryItem> _loadedItems=[];
      for(final item in listData.entries){
        final category=categories.entries.firstWhere((catItem) => catItem.value.title == item.value['category']).value;
        _loadedItems.add(GroceryItem(id: item.key, name: item.value['name'], quantity: item.value['quantity'], category: category,));
      }
      setState(() {
        _groceryItems=_loadedItems;
        _isLoading=false;
      });
    }

    catch(err){
      setState(() {
        _error='Something went wrong!,Please try again later.';
      });
    }

  }

  void add_item() async {
    final newItem=await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
          builder: (ctx)=> const NewItem()
    ),
    );
    
    if(newItem==null){
      return;
    }
    setState(() {
      _groceryItems.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async
  {
    final index=_groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });
    final url=Uri.https('flutter-prep-b773f-default-rtdb.firebaseio.com','shopping-list/${item.id}.json');
    final response=await http.delete(url);

    if(response.statusCode>=400){
      _groceryItems.insert(index, item);
    }

  }


  @override
  Widget build(BuildContext context) {
    Widget content=const Center(
      child: Text(
          "No item added yet"
      ),
    );

    if(_isLoading){
      content=const Center(child: CircularProgressIndicator());
    }

    if(_groceryItems.isNotEmpty){
      content =ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (ctx,index)=>Dismissible(
          key: ValueKey(_groceryItems[index].id),
          onDismissed: (direction){
            _removeItem(_groceryItems[index]);
          },
          child: ListTile(
            title: Text(_groceryItems[index].name,),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItems[index].category.color,
            ),
            trailing: Text(_groceryItems[index].quantity.toString()),
          ),
        ),
      );
    }
    if(_error != null)
      {
        content=Center(child: Text(_error!),);
      }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Grocery"),
        actions: [
          IconButton(
              onPressed: add_item,
              icon: const Icon(Icons.add))
        ],
      ),
      body: content,
    );
  }
}
