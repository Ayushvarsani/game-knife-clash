import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../game/managers/high_score_manager.dart';
import 'widgets/stripe_background.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = true;
  bool _hapticsEnabled = true;

  final HighScoreManager _hsm = HighScoreManager();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await _hsm.load();
    if (!mounted) return;
    setState(() {
      _soundEnabled = prefs.getBool('settings_sound') ?? true;
      _hapticsEnabled = prefs.getBool('settings_haptics') ?? true;
      _loaded = true;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('settings_sound', _soundEnabled);
    await prefs.setBool('settings_haptics', _hapticsEnabled);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C0709),
      appBar: AppBar(
        backgroundColor: const Color(0xFF120405),
        foregroundColor: Colors.white,
        title: Text(
          'SETTINGS',
          style: GoogleFonts.rajdhani(
            fontWeight: FontWeight.w900,
            letterSpacing: 5,
            fontSize: 21,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.white10),
        ),
      ),
      body: StripeBackground(
        child: !_loaded
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFf39c12)))
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.07),
                          Colors.white.withValues(alpha: 0.03),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        _sectionHeader('AUDIO & FEEDBACK'),
                        const SizedBox(height: 12),
                        _toggleRow(
                          icon: Icons.volume_up_rounded,
                          iconColor: const Color(0xFF3498db),
                          label: 'Sound',
                          value: _soundEnabled,
                          onChanged: (v) {
                            setState(() => _soundEnabled = v);
                            _saveSettings();
                          },
                        ),
                        const SizedBox(height: 10),
                        _toggleRow(
                          icon: Icons.vibration_rounded,
                          iconColor: const Color(0xFFf39c12),
                          label: 'Vibration',
                          value: _hapticsEnabled,
                          onChanged: (v) {
                            setState(() => _hapticsEnabled = v);
                            _saveSettings();
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.06),
                          Colors.white.withValues(alpha: 0.025),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.11),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        _sectionHeader('HIGH SCORE'),
                        const SizedBox(height: 12),
                        _highScoreCard(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _sectionHeader(String text) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: const Color(0xFFf39c12),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: GoogleFonts.rajdhani(
            color: Colors.white60,
            fontSize: 12,
            letterSpacing: 2.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _toggleRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.rajdhani(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFFFF7A1A),
            activeTrackColor: const Color(0xFFFF7A1A).withValues(alpha: 0.35),
            inactiveThumbColor: Colors.white38,
            inactiveTrackColor: Colors.white24,
          ),
        ],
      ),
    );
  }

  Widget _highScoreCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded,
              color: Color(0xFFFFD700), size: 28),
          const SizedBox(width: 14),
          Text(
            'BEST SCORE',
            style: GoogleFonts.rajdhani(
              color: Colors.white60,
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const Spacer(),
          Text(
            '${_hsm.highScore}',
            style: GoogleFonts.rajdhani(
              color: const Color(0xFFFFD700),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
