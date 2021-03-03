import 'package:flutter/material.dart';

class MAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget leading;
  final List<Widget> actions;
  final bool centerTitle;

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);

  MAppBar({
    this.title,
    this.leading,
    this.actions,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      centerTitle: centerTitle,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              'lib/src/modules/future-map/assets/appbar_background.png',
            ),
            fit: BoxFit.cover,
          ),
        ),
      ),
      title: Text(
        title,
      ),
      leading: leading,
      actions: actions,
    );
  }
}
