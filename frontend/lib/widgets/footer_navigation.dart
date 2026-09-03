import 'package:flutter/material.dart';

class FooterNavigation extends StatefulWidget {
  const FooterNavigation({super.key, this.activeIndex = 0, this.onItemTap});

  final int activeIndex;
  final ValueChanged<int>? onItemTap;

  @override
  State<FooterNavigation> createState() => _FooterNavigationState();
}

class _FooterNavigationState extends State<FooterNavigation> {
  late int _selectedIndex = widget.activeIndex;

  @override
  void didUpdateWidget(covariant FooterNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeIndex != widget.activeIndex) {
      _selectedIndex = widget.activeIndex;
    }
  }

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavItem(Icons.home_outlined, 'ホーム'),
      _NavItem(Icons.storefront_outlined, 'ショップ'),
      _NavItem(Icons.face_3_outlined, 'キャスト'),
      _NavItem(Icons.shopping_cart_outlined, 'オーダー'),
      _NavItem(Icons.person_outline_rounded, 'マイページ'),
    ];

    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: Color(0xEE171716),
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Stack(
        children: [
          Container(height: 1, color: const Color(0xFF3B362F)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var index = 0; index < items.length; index++)
                SizedBox(
                  width: 64,
                  height: 72,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (widget.activeIndex >= 0) {
                        setState(() => _selectedIndex = index);
                      }
                      widget.onItemTap?.call(index);
                    },
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        splashColor: const Color(0x33F1D084),
                        highlightColor: const Color(0x18F1D084),
                        onTap: null,
                        child: SizedBox.expand(
                          child: Column(
                            children: [
                              const SizedBox(height: 9),
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color:
                                      _selectedIndex >= 0 &&
                                          index == _selectedIndex
                                      ? const Color(0x18D7B56D)
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  items[index].icon,
                                  size: items[index].label == 'ショップ' ? 23 : 22,
                                  color:
                                      _selectedIndex >= 0 &&
                                          index == _selectedIndex
                                      ? const Color(0xFFF1D084)
                                      : const Color(0xFFBDBDC2),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                items[index].label,
                                maxLines: 1,
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  color: index == _selectedIndex
                                      ? const Color(0xFFF1D084)
                                      : const Color(0xFFBDBDC2),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          Positioned(
            left: 114,
            bottom: 7,
            child: Container(
              width: 124,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.label);

  final IconData icon;
  final String label;
}
