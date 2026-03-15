// lib/presentation/screens/sura_list/sura_list_screen.dart

import 'package:flutter/material.dart';
import '../../theme/color.dart';
import '../../../core/constants/quran_constants.dart';
import '../recitation/recitation_screen.dart';
import '../recitation/recitation_state.dart';

class SuraListScreen extends StatefulWidget {
  const SuraListScreen({super.key});

  @override
  State<SuraListScreen> createState() => _SuraListScreenState();
}

class _SuraListScreenState extends State<SuraListScreen> {
  String _searchQuery = '';
  String _filter = 'all'; // all / meccan / medinan

  List<Map<String, dynamic>> get _filteredSuras {
    var suras = QuranConstants.suraList.where((s) {
      if (_filter == 'meccan' && s['type'] != 'M') return false;
      if (_filter == 'medinan' && s['type'] != 'L') return false;
      if (_searchQuery.isNotEmpty) {
        final name = s['name'] as String;
        final nameEn = s['nameEn'] as String;
        if (!name.contains(_searchQuery) && !nameEn.toLowerCase().contains(_searchQuery.toLowerCase())) {
          return false;
        }
      }
      return true;
    }).toList();
    return suras;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('السور القرآنية'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            // البحث والتصفية
            _SearchFilterBar(
              onSearch: (q) => setState(() => _searchQuery = q),
              onFilter: (f) => setState(() => _filter = f),
              currentFilter: _filter,
            ),
            // قائمة السور
            Expanded(
              child: ListView.builder(
                itemCount: _filteredSuras.length,
                itemBuilder: (context, index) {
                  final sura = _filteredSuras[index];
                  return _SuraListTile(
                    sura: sura,
                    onTap: () {
                      final pageNumber = sura['page'] as int;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RecitationScreen(
                            pageNumber: pageNumber,
                            mode: RecitationMode.hidden,
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchFilterBar extends StatelessWidget {
  final Function(String) onSearch;
  final Function(String) onFilter;
  final String currentFilter;

  const _SearchFilterBar({
    required this.onSearch,
    required this.onFilter,
    required this.currentFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        children: [
          TextField(
            onChanged: onSearch,
            textDirection: TextDirection.rtl,
            decoration: InputDecoration(
              hintText: 'ابحث عن سورة...',
              prefixIcon: const Icon(Icons.search, color: AppColors.textHint),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _FilterChip(
                label: 'الكل',
                value: 'all',
                currentFilter: currentFilter,
                onTap: onFilter,
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'مكية',
                value: 'meccan',
                currentFilter: currentFilter,
                onTap: onFilter,
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'مدنية',
                value: 'medinan',
                currentFilter: currentFilter,
                onTap: onFilter,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String currentFilter;
  final Function(String) onTap;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.currentFilter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentFilter == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.textHint,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 13,
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _SuraListTile extends StatelessWidget {
  final Map<String, dynamic> sura;
  final VoidCallback onTap;

  const _SuraListTile({required this.sura, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final number = sura['number'] as int;
    final name = sura['name'] as String;
    final ayahs = sura['ayahs'] as int;
    final type = sura['type'] as String;
    final page = sura['page'] as int;
    final isMeccan = type == 'M';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // رقم السورة
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // معلومات السورة
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '$ayahs آية',
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: isMeccan
                                ? AppColors.secondary.withValues(alpha: 0.15)
                                : AppColors.primaryLight.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isMeccan ? 'مكية' : 'مدنية',
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 11,
                              color: isMeccan ? AppColors.secondary : AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // صفحة المصحف
              Column(
                children: [
                  const Icon(Icons.book_outlined, size: 14, color: AppColors.textHint),
                  Text(
                    'ص$page',
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_back_ios, size: 14, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }
}
