import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_list.dart';
import 'package:firebase_rtd_paginate/firebase_rtd_paginate.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

part 'pagination_event.dart';
part 'pagination_state.dart';

class PaginationBloc<T> extends Bloc<PaginationEvent, PaginationState> {
  PaginationBloc(
      this._query,
      this._limit,
      this._lastVal,
      this._attribute,
      this.modelBuilder,
      this.comparatorItem,
      this.timeOut,
      ) : super(PaginationInitial());

  int _lastVal;
  int timeOut;
  String _attribute;
  String _lastDocument;
  final Query _query;
  final int _limit;
  final ModelBuilder<T> modelBuilder;
  final ComparatorItem<T> comparatorItem;

  @override
  Stream<PaginationState> mapEventToState(
      PaginationEvent event,
      ) async* {

    if (event is PageRefreshed) {
      _lastDocument = null;
      final newItems = await _getData();
      yield PaginationLoaded<T>(
        data: newItems,
      );
      return;
    }

  if (event is PageFetch) {
    final currentState = state;
      try {
        if (currentState is PaginationInitial) {
          final newItems = await _getData();
          yield PaginationLoaded<T>(
            data: newItems,
          );
          return;
        }
        if (currentState is PaginationLoaded) {
          final newItems = await _getData(currentData: currentState.data);
          yield currentState.copyWith(
            data: newItems,
          );
          return;
        }
      } on Exception catch (error) {
        yield PaginationError(error: error);
      }
    }
  }


  Future<void> _getOrdered(Set<T> set, Query query, int callLimit) async{
    query = query.limitToLast(callLimit);
    var list;
    list = FirebaseList(query: query,
        onChildAdded: (pos, snapshot) {},
        onChildRemoved: (pos, snapshot) {},
        onChildChanged: (pos, snapshot) {},
        onChildMoved: (oldpos, newpos, snapshot) {},
        onValue: (snapshot) {
          for (var i=0; i < list.length; i++) {
            set.add(modelBuilder(list[i].value, list[i].key));
          }
          _lastVal = list[0].value[_attribute];
          _lastDocument = list[0].key;
        }
    );

    await Future.delayed(Duration(milliseconds: timeOut));
  }

  Future<List<T>> _getData({List<T> currentData}) async {
    final localQuery = (_lastDocument != null)
        ? _query.orderByChild(_attribute).endAt(_lastVal, key: _lastDocument)
        : _query.orderByChild(_attribute);

    try {
      var newData = currentData == null ? Set<T>() : currentData.toSet();

      int initialLen = newData.length;
      int callLimit = _limit;

      if(_lastDocument == null){
        await _getOrdered(newData, localQuery, callLimit);
      }else {
        while(callLimit != 0){
          await _getOrdered(newData, localQuery, callLimit);
          callLimit -= (newData.length - initialLen);
          if(newData.length == initialLen){
            break;
          }
          initialLen = newData.length;
        }
      }

      var result = newData.toList();
      result.sort(comparatorItem);
      return result;
    } on PlatformException catch (exception) {
      print(exception);
      rethrow;
    }
  }
}
