// lib/presentation/screens/settings/settings_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/color.dart';
import '../../../core/constants/recitation_constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _silenceThreshold = RecitationConstants.forgettingThresholdMs / 1000.0;
  double _fontSize = 22.0;
  bool _isDarkMode = false;
  bool _showDiacritics = true;
  bool _autoAdvanceOnDiacError = true;
  String _defaultMode = 'HIDDEN';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _silenceThreshold = prefs.getDouble('silence_threshold') ?? 3.0;
        _fontSize = prefs.getDouble('quran_font_size') ?? 22.0;
        _isDarkMode = prefs.getBool('dark_mode') ?? false;
        _showDiacritics = prefs.getBool('show_diacritics') ?? true;
        _autoAdvanceOnDiacError = prefs.getBool('auto_advance_diac') ?? true;
        _defaultMode = prefs.getString('default_mode') ?? 'HIDDEN';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('silence_threshold', _silenceThreshold);
    await prefs.setDouble('quran_font_size', _fontSize);
    await prefs.setBool('dark_mode', _isDarkMode);
    await prefs.setBool('show_diacritics', _showDiacritics);
    await prefs.setBool('auto_advance_diac', _autoAdvanceOnDiacError);
    await prefs.setString('default_mode', _defaultMode);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تم حفظ الإعدادات',
            style: TextStyle(fontFamily: 'Amiri'),
            textDirection: TextDirection.rtl,
          ),
          backgroundColor: AppColors.primary,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('الإعدادات'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            TextButton(
              onPressed: _saveSettings,
              child: const Text(
                'حفظ',
                style: TextStyle(color: Colors.white, fontFamily: 'Amiri', fontSize: 16),
              ),
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ═══ إعدادات التسميع ═══
                  _SettingsSection(
                    title: 'إعدادات التسميع',
                    icon: Icons.mic_rounded,
                    children: [
                      // عتبة الصمت
                      _SliderSetting(
                        title: 'عتبة الصمت (ثانية)',
                        subtitle: 'المدة التي يُعدّ بعدها الصمت نسياناً',
                        value: _silenceThreshold,
                        min: 1.0,
                        max: 8.0,
                        divisions: 14,
                        label: '${_silenceThreshold.toStringAsFixed(1)} ث',
                        onChanged: (v) => setState(() => _silenceThreshold = v),
                      ),

                      // وضع الافتراضي
                      _DropdownSetting(
                        title: 'وضع التسميع الافتراضي',
                        value: _defaultMode,
                        items: const {
                          'HIDDEN': 'مخفي (تحفيظ)',
                          'VISIBLE': 'مرئي (مراجعة)',
                        },
                        onChanged: (v) => setState(() => _defaultMode = v!),
                      ),

                      // الانتقال التلقائي عند خطأ التشكيل
                      _SwitchSetting(
                        title: 'انتقال تلقائي عند خطأ التشكيل',
                        subtitle: 'الانتقال للكلمة التالية بعد 2 ث عند خطأ التشكيل',
                        value: _autoAdvanceOnDiacError,
                        onChanged: (v) => setState(() => _autoAdvanceOnDiacError = v),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ═══ إعدادات العرض ═══
                  _SettingsSection(
                    title: 'إعدادات العرض',
                    icon: Icons.display_settings_rounded,
                    children: [
                      // حجم الخط
                      _SliderSetting(
                        title: 'حجم خط القرآن',
                        subtitle: 'الحجم الافتراضي 22',
                        value: _fontSize,
                        min: 16.0,
                        max: 36.0,
                        divisions: 10,
                        label: '${_fontSize.toInt()}',
                        onChanged: (v) => setState(() => _fontSize = v),
                        preview: Text(
                          'بِسۡمِ ٱللَّهِ',
                          style: TextStyle(
                            fontFamily: 'AmiriQuran',
                            fontSize: _fontSize,
                            color: AppColors.textQuran,
                            height: 2.0,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                      ),

                      // إظهار التشكيل
                      _SwitchSetting(
                        title: 'إظهار التشكيل',
                        subtitle: 'عرض الحركات والتشكيل في النص القرآني',
                        value: _showDiacritics,
                        onChanged: (v) => setState(() => _showDiacritics = v),
                      ),

                      // الوضع الليلي
                      _SwitchSetting(
                        title: 'الوضع الليلي',
                        subtitle: 'تفعيل المظهر الداكن للتطبيق',
                        value: _isDarkMode,
                        onChanged: (v) => setState(() => _isDarkMode = v),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ═══ معلومات التطبيق ═══
                  _SettingsSection(
                    title: 'حول التطبيق',
                    icon: Icons.info_outline_rounded,
                    children: [
                      _InfoTile(
                        title: 'الإصدار',
                        value: '1.0.0',
                      ),
                      _InfoTile(
                        title: 'بيانات القرآن',
                        value: 'KFGQPC Hafs Uthmani Script',
                      ),
                      _InfoTile(
                        title: 'نموذج التعرف',
                        value: 'Mock ASR Engine (Testing)',
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}

// ═══════════════ مكونات الإعدادات ═══════════════
class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SwitchSetting extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final Function(bool) onChanged;

  const _SwitchSetting({
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(fontFamily: 'Amiri', fontSize: 14),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: const TextStyle(fontFamily: 'Amiri', fontSize: 11),
            )
          : null,
      value: value,
      onChanged: onChanged,
      activeThumbColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
    );
  }
}

class _SliderSetting extends StatelessWidget {
  final String title;
  final String? subtitle;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final String? label;
  final Function(double) onChanged;
  final Widget? preview;

  const _SliderSetting({
    required this.title,
    this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    this.label,
    required this.onChanged,
    this.preview,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontFamily: 'Amiri', fontSize: 14),
            ),
            if (label != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label!,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 13,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        if (subtitle != null)
          Text(
            subtitle!,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 11,
              color: AppColors.textHint,
            ),
          ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
          activeColor: AppColors.primary,
        ),
        if (preview != null) Center(child: preview!),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _DropdownSetting extends StatelessWidget {
  final String title;
  final String value;
  final Map<String, String> items;
  final Function(String?) onChanged;

  const _DropdownSetting({
    required this.title,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontFamily: 'Amiri', fontSize: 14),
          ),
          DropdownButton<String>(
            value: value,
            items: items.entries.map((e) {
              return DropdownMenuItem(
                value: e.key,
                child: Text(
                  e.value,
                  style: const TextStyle(fontFamily: 'Amiri', fontSize: 13),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String value;

  const _InfoTile({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
