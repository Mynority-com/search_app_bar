import 'dart:math';

import 'package:flutter/material.dart';

import 'app_bar_painter.dart';
import 'search_widget.dart';
import 'searcher.dart';

class SearchAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Searcher searcher;
  final Widget title;
  final bool centerTitle;
  final IconThemeData iconTheme;
  final Color backgroundColor;
  final Color searchBackgroundColor;
  final Color searchElementsColor;
  final String hintText;
  final bool flattenOnSearch;
  final TextCapitalization capitalization;
  final List<Widget> actions;
  final int _searchButtonPosition;

  SearchAppBar({
    @required this.searcher,
    this.title,
    this.centerTitle = false,
    this.iconTheme,
    this.backgroundColor,
    this.searchBackgroundColor,
    this.searchElementsColor,
    this.hintText,
    this.flattenOnSearch = false,
    this.capitalization = TextCapitalization.none,
    this.actions = const <Widget>[],
    int searchButtonPosition,
  }) : _searchButtonPosition = (searchButtonPosition != null &&
                (0 <= searchButtonPosition &&
                    searchButtonPosition <= actions.length))
            ? searchButtonPosition
            : max(actions.length, 0);
  // search button position defaults to the end.

  @override
  Size get preferredSize => Size.fromHeight(56.0);

  _SearchAppBarState createState() => _SearchAppBarState();
}

class _SearchAppBarState extends State<SearchAppBar>
    with SingleTickerProviderStateMixin {
  double _rippleStartX, _rippleStartY;
  AnimationController _controller;
  Animation _animation;
  double _elevation = 4.0;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 150));
    _animation = Tween(begin: 0.0, end: 1.0).animate(_controller);
    _controller.addStatusListener(animationStatusListener);
  }

  animationStatusListener(AnimationStatus animationStatus) {
    if (animationStatus == AnimationStatus.completed) {
      widget.searcher.setSearchMode(true);
      if (widget.flattenOnSearch) _elevation = 0.0;
    }
  }

  void onSearchTapUp(TapUpDetails details) {
    _rippleStartX = details.globalPosition.dx;
    _rippleStartY = details.globalPosition.dy;
    _controller.forward();
  }

  void cancelSearch() {
    widget.searcher.setSearchMode(false);
    widget.searcher.onClearSearchQuery();
    _elevation = 4.0;
    _controller.reverse();
  }

  Future<bool> _onWillPop(bool isInSearchMode) async {
    if (isInSearchMode) {
      cancelSearch();
      return false;
    } else {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return StreamBuilder<bool>(
        stream: widget.searcher.isInSearchMode,
        builder: (context, snapshot) {
          final isInSearchMode = snapshot.data ?? false;
          return WillPopScope(
            onWillPop: () => _onWillPop(isInSearchMode),
            child: Stack(
              children: [
                _buildAppBar(context),
                _buildAnimation(screenWidth),
                _buildSearchWidget(isInSearchMode, context),
              ],
            ),
          );
        });
  }

  AppBar _buildAppBar(BuildContext context) {
    final searchButton = _buildSearchButton(context);
    final increasedActions = List<Widget>();
    increasedActions.addAll(widget.actions);
    increasedActions.insert(widget._searchButtonPosition, searchButton);
    return AppBar(
      backgroundColor: widget.backgroundColor ?? Theme.of(context).primaryColor,
      iconTheme: widget.iconTheme ?? Theme.of(context).iconTheme,
      title: widget.title,
      elevation: _elevation,
      centerTitle: widget.centerTitle,
      actions: increasedActions,
    );
  }

  Widget _buildSearchButton(BuildContext context) {
    return GestureDetector(
      child: IconButton(
        onPressed: null,
        icon: Icon(
          Icons.search,
          color: widget.iconTheme?.color ?? Theme.of(context).iconTheme.color,
        ),
      ),
      onTapUp: onSearchTapUp,
    );
  }

  AnimatedBuilder _buildAnimation(double screenWidth) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          painter: AppBarPainter(
            containerHeight: widget.preferredSize.height,
            center: Offset(_rippleStartX ?? 0, _rippleStartY ?? 0),
            // increase radius in % from 0% to 100% of screenWidth
            radius: _animation.value * screenWidth,
            context: context,
            color: widget.searchBackgroundColor ?? Colors.white,
          ),
        );
      },
    );
  }

  Widget _buildSearchWidget(bool isInSearchMode, BuildContext context) {
    return isInSearchMode
        ? SearchWidget(
            searcher: widget.searcher,
            color: widget.searchElementsColor ?? Theme.of(context).primaryColor,
            onCancelSearch: cancelSearch,
            textCapitalization: widget.capitalization,
            hintText: widget.hintText,
          )
        : Container();
  }
}
