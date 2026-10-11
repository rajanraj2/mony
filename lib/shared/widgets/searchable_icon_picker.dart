import 'package:flutter/material.dart';
import '../utils/icon_registry.dart';

class SearchableIconPicker extends StatefulWidget {
  final String selectedIconId;
  final ValueChanged<IconItem> onIconSelected;

  const SearchableIconPicker({
    super.key,
    required this.selectedIconId,
    required this.onIconSelected,
  });

  static Future<IconItem?> show(BuildContext context, {String initialIconId = 'account_balance'}) {
    return showModalBottomSheet<IconItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Color(0xFF151B23),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SearchableIconPicker(
          selectedIconId: initialIconId,
          onIconSelected: (icon) => Navigator.pop(ctx, icon),
        ),
      ),
    );
  }

  @override
  State<SearchableIconPicker> createState() => _SearchableIconPickerState();
}

class _SearchableIconPickerState extends State<SearchableIconPicker> {
  final _searchCtrl = TextEditingController();
  List<IconItem> _filtered = IconRegistry.allIcons;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() {
        _filtered = IconRegistry.search(_searchCtrl.text);
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Select Icon', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Search Field
          TextField(
            controller: _searchCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search icon by name, category or tag (e.g. food, car, crypto)...',
              hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF0D1117),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),

          // Icon Grid
          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Text('No icons found', style: TextStyle(color: Colors.grey)))
                : GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, i) {
                      final item = _filtered[i];
                      final isSelected = item.id == widget.selectedIconId;

                      return InkWell(
                        onTap: () => widget.onIconSelected(item),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF22C55E).withOpacity(0.2) : const Color(0xFF0D1117),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF22C55E) : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(item.iconData, color: isSelected ? const Color(0xFF22C55E) : Colors.white, size: 28),
                              const SizedBox(height: 6),
                              Text(
                                item.name,
                                style: TextStyle(
                                  color: isSelected ? const Color(0xFF22C55E) : Colors.grey.shade400,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
