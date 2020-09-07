/*
MIT License

Copyright (c) 2020 Venkatesh Prasad

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

library firebase_rtd_paginate;

import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_rtd_paginate/bloc/pagination_bloc.dart';
import 'package:firebase_rtd_paginate/widgets/bottom_loader.dart';
import 'package:firebase_rtd_paginate/widgets/empty_display.dart';
import 'package:firebase_rtd_paginate/widgets/empty_separator.dart';
import 'package:firebase_rtd_paginate/widgets/error_display.dart';
import 'package:firebase_rtd_paginate/widgets/initial_loader.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';

typedef T ModelBuilder<T>(dynamic item, dynamic key);
typedef int ComparatorItem<T>(T left, T right);
typedef Widget ItemWidgetBuilder<T>(BuildContext context, T item, int index);

class FirebaseRTDPaginate<T> extends StatefulWidget {
  FirebaseRTDPaginate(
      {Key key,
        @required this.query,
        @required this.itemWidgetBuilder,
        @required this.modelBuilder,
        @required this.comparatorItem,
        @required this.attribute,
        this.lastVal,
        this.gridDelegate =
        const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
        this.itemsPerPage = 15,
        this.onError,
        this.emptyDisplay = const EmptyDisplay(),
        this.separator = const EmptySeparator(),
        this.initialLoader = const InitialLoader(),
        this.bottomLoader = const BottomLoader(),
        this.shrinkWrap = false,
        this.reverse = false,
        this.scrollDirection = Axis.vertical,
        this.padding = const EdgeInsets.all(0),
        this.itemBuilderType,
        this.timeOut = 1000,
        this.physics})
      : super(key: key);

  final ComparatorItem<T> comparatorItem;
  final ModelBuilder<T> modelBuilder;
  final ItemWidgetBuilder<T> itemWidgetBuilder;
  final Widget bottomLoader;
  final Widget emptyDisplay;
  final SliverGridDelegate gridDelegate;
  final Widget initialLoader;
  final dynamic itemBuilderType;
  final int itemsPerPage;
  final EdgeInsets padding;
  final ScrollPhysics physics;
  final Query query;
  final bool reverse;
  final Axis scrollDirection;
  final Widget separator;
  final bool shrinkWrap;
  final String attribute;
  final int lastVal;
  final int timeOut;

  @override
  _FirebaseRTDPaginateState createState() => _FirebaseRTDPaginateState<T>();

  final Widget Function(Exception) onError;
}

class _FirebaseRTDPaginateState<T> extends State<FirebaseRTDPaginate<T>> {

  PaginationBloc _bloc;
  final _scrollController = ScrollController();
  RefreshController _refreshController = RefreshController(initialRefresh: false);


  void _onRefresh() async{
    // monitor network fetch
    await Future.delayed(Duration(milliseconds: 1000));
    // if failed,use refreshFailed()
    _bloc.add(PageRefreshed());

    _refreshController.refreshCompleted(resetFooterState: true);
  }

  void _onLoading() async{
    // monitor network fetch
    await Future.delayed(Duration(milliseconds: 1000));
    // if failed,use loadFailed(),if no data return,use LoadNodata()
    _bloc.add(PageFetch());
    _refreshController.loadComplete();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PaginationBloc, PaginationState>(
      cubit: _bloc,
      builder: (context, state) {
        if (state is PaginationInitial) {
          return widget.initialLoader;
        } else if (state is PaginationError) {
          return (widget.onError != null)
              ? widget.onError(state.error)
              : ErrorDisplay(exception: state.error);
        } else {
          final loadedState = state as PaginationLoaded;
          if (loadedState.data.isEmpty) {
            return widget.emptyDisplay;
          }
          return Container(
            padding: widget.padding,
              child: SmartRefresher(
              enablePullDown: true,
              enablePullUp: true,
              header: WaterDropHeader(),
              footer: CustomFooter(
                loadStyle: LoadStyle.ShowWhenLoading,
                builder: (BuildContext context,LoadStatus mode){
                  Widget body ;
                  if(mode==LoadStatus.loading){
                    body =  CupertinoActivityIndicator();
                  }
                  return Container(
                    height: 50.0,
                    child: Center(child:body),
                    color: Colors.black54,
                  );
                },
              ),
              controller: _refreshController,
              onRefresh: _onRefresh,
              onLoading: _onLoading,
              child: widget.itemBuilderType == PaginateBuilderType.listView
                  ? _buildListView(loadedState)
                  : _buildGridView(loadedState)

              )
          );

//
//
//            widget.itemBuilderType == PaginateBuilderType.listView
//              ? _buildListView(loadedState)
//              : _buildGridView(loadedState);
        }
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _bloc = PaginationBloc<T>(
      widget.query,
      widget.itemsPerPage,
      widget.lastVal,
      widget.attribute,
      widget.modelBuilder,
      widget.comparatorItem,
      widget.timeOut,
    )..add(PageFetch());
  }

  Widget _buildGridView(PaginationLoaded loadedState) {
    return GridView.builder(
      controller: _scrollController,
      itemCount: loadedState.data.length,
      gridDelegate: widget.gridDelegate,
      reverse: widget.reverse,
      shrinkWrap: widget.shrinkWrap,
      scrollDirection: widget.scrollDirection,
      physics: widget.physics,
      itemBuilder: (context, index) {
        return widget.itemWidgetBuilder(
            context, loadedState.data[index], index);
      },
    );
  }

  Widget _buildListView(PaginationLoaded loadedState) {
    return ListView.separated(
      controller: _scrollController,
      reverse: widget.reverse,
      shrinkWrap: widget.shrinkWrap,
      scrollDirection: widget.scrollDirection,
      physics: widget.physics,
      separatorBuilder: (context, index) => widget.separator,
      itemCount: loadedState.data.length,
      itemBuilder: (context, index) {
        return widget.itemWidgetBuilder(
            context, loadedState.data[index], index);
      },
    );
  }
}

enum PaginateBuilderType { listView, gridView }
