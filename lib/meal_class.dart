import 'package:flutter/material.dart';


class Meal{
  String title;
  String preparationTime;
  String price;
  String ingredients;
  String valoareEnergetica;
  String alergeni;
  //String kitchenOrBar;
  //String category; //felul1,felul2,desert,bautura

  Meal({required this.title, required this.preparationTime, required this.price, required this.ingredients, required this.valoareEnergetica, required this.alergeni});

  getTitle(title){ this.title = title; }
  getPreparationTime(preparationTime) { this.preparationTime = preparationTime; }
  getPrice(price) { this.price = price; }
  getIngredients(ingredients) { this.ingredients = ingredients; }
  getValoareEnergetica(valoareEnergetica) {this.valoareEnergetica = valoareEnergetica; }
  getAlergeni(alergeni) { this.alergeni = alergeni; }

  
  
}