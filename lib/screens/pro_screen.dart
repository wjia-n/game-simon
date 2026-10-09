import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/simon_themes.dart';
import 'widgets.dart';

/// Simon PRO: Free-vs-Pro comparison, real purchase, restore, and tip jar.
/// All prices come from the store — never hardcoded, never placeholders.
class ProScreen extends StatefulWidget {
  final SimonAudio audio;
  final SimonSettings settings;
  final StoreService store;

  const ProScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
  });

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  SimonThemeDef get _t => SimonThemes.byId(
        widget.settings.themeId,
        custom: widget.settings.customTheme,
      );

  @override
  void initState() {
    super.initState();
    widget.store.proPurchased.addListener(_onPro);
    widget.store.lastThanks.addListener(_onThanks);
  }

  void _onPro() {
    if (widget.store.proPurchased.value && mounted) {
      widget.settings.setPro(true);
      widget.audio.win();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PRO unlocked — enjoy everything!',
              style: TextStyle(color: _t.text, fontSize: 15)),
          backgroundColor: _t.cabinetDeep,
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.store.proPurchased.value = false;
    }
  }

  void _onThanks() {
    final msg = widget.store.lastThanks.value;
    if (msg == null || !mounted) return;
    widget.audio.win();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: TextStyle(color: _t.text, fontSize: 15)),
        backgroundColor: _t.cabinetDeep,
        behavior: SnackBarBehavior.floating,
      ),
    );
    widget.store.lastThanks.value = null;
  }

  @override
  void dispose() {
    widget.store.proPurchased.removeListener(_onPro);
    widget.store.lastThanks.removeListener(_onThanks);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    final store = widget.store;
    return Cabinet(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: t.accent),
            onPressed: () {
              widget.audio.click();
              Navigator.of(context).pop();
            },
          ),
          title: Text('Simon PRO',
              style: TextStyle(
                  color: t.text, fontWeight: FontWeight.w900, fontSize: 22)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: Column(
                children: [
                  _ComparisonCard(theme: t, isPro: s.isPro),
                  const SizedBox(height: 16),
                  _BuyCard(
                    theme: t,
                    settings: s,
                    store: store,
                    audio: widget.audio,
                  ),
                  const SizedBox(height: 16),
                  _TipsCard(
                    theme: t,
                    store: store,
                    audio: widget.audio,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Free vs Pro comparison table — buyers see the big difference.
class _ComparisonCard extends StatelessWidget {
  final SimonThemeDef theme;
  final bool isPro;
  const _ComparisonCard({required this.theme, required this.isPro});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Complete Simon game', true, true),
      ('All official rules', true, true),
      ('Solo & Endless modes', true, true),
      ('Chill & Classic speeds', true, true),
      ('Renameable player profile', true, true),
      ('Music & sound effects', true, true),
      ('Cabinet themes', '4', '12+'),
      ('Pad styles', '4', '8'),
      ('Custom theme creator', false, true),
      ('Turbo difficulty', false, true),
      ('Score Attack mode', false, true),
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black.withValues(alpha: 0.35),
        border: Border.all(color: theme.accent, width: 2),
      ),
      child: Column(
        children: [
          Text('Free vs PRO',
              style: TextStyle(
                  color: theme.text,
                  fontWeight: FontWeight.w900,
                  fontSize: 20)),
          const SizedBox(height: 4),
          Text(
            'One purchase. Yours forever.',
            style: TextStyle(
                color: theme.muted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          // Header row.
          Row(
            children: [
              const Expanded(flex: 5, child: SizedBox()),
              Expanded(
                  flex: 2,
                  child: Text('FREE',
                      style: TextStyle(
                          color: theme.muted,
                          fontWeight: FontWeight.w800,
                          fontSize: 12),
                      textAlign: TextAlign.center)),
              Expanded(
                  flex: 2,
                  child: Text('PRO',
                      style: TextStyle(
                          color: theme.accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 12),
                      textAlign: TextAlign.center)),
            ],
          ),
          Divider(height: 14, color: theme.accent.withValues(alpha: 0.3)),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: Text(r.$1,
                        style: TextStyle(
                            color: theme.text, fontSize: 13)),
                  ),
                  Expanded(flex: 2, child: _Cell(value: r.$2, theme: theme)),
                  Expanded(flex: 2, child: _Cell(value: r.$3, theme: theme)),
                ],
              ),
            ),
          if (isPro)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: theme.accent.withValues(alpha: 0.25),
                  border: Border.all(color: theme.accent),
                ),
                child: Text('✦ PRO ACTIVE ✦',
                    style: TextStyle(
                        color: theme.accent,
                        fontWeight: FontWeight.w900,
                        fontSize: 14)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final Object value; // bool | String
  final SimonThemeDef theme;
  const _Cell({required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (value is bool) {
      final v = value as bool;
      return Text(
        v ? '✓' : '—',
        style: TextStyle(
            color: v ? theme.accent : theme.muted.withValues(alpha: 0.4),
            fontSize: 15,
            fontWeight: FontWeight.w800),
        textAlign: TextAlign.center,
      );
    }
    return Text(
      value as String,
      style: TextStyle(
          color: theme.accent, fontWeight: FontWeight.w800, fontSize: 12),
      textAlign: TextAlign.center,
    );
  }
}

// ---------------------------------------------------------------------------
class _BuyCard extends StatelessWidget {
  final SimonThemeDef theme;
  final SimonSettings settings;
  final StoreService store;
  final SimonAudio audio;
  const _BuyCard({
    required this.theme,
    required this.settings,
    required this.store,
    required this.audio,
  });

  @override
  Widget build(BuildContext context) {
    final pro = store.proProduct;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black.withValues(alpha: 0.35),
        border: Border.all(color: theme.accent, width: 2),
      ),
      child: Column(
        children: [
          Text('Unlock PRO',
              style: TextStyle(
                  color: theme.text,
                  fontWeight: FontWeight.w900,
                  fontSize: 20)),
          const SizedBox(height: 8),
          if (settings.isPro)
            Text('You already own PRO — thank you!',
                style: TextStyle(color: theme.text, fontSize: 14),
                textAlign: TextAlign.center)
          else if (!store.storeReady)
            Text(
              store.error ?? 'Available after store setup.',
              style: TextStyle(
                  color: theme.muted, fontSize: 14),
              textAlign: TextAlign.center,
            )
          else if (pro != null) ...[
            Text(pro.description.isNotEmpty
                ? pro.description
                : 'Unlock everything in Simon, forever.',
                style: TextStyle(color: theme.text, fontSize: 14),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ValueListenableBuilder<bool>(
              valueListenable: store.purchaseInProgress,
              builder: (_, busy, _) => ArcadeButton(
                label: busy ? 'Working…' : 'Get PRO — ${pro.price}',
                theme: theme,
                primary: true,
                width: 260,
                onTap: busy
                    ? () {}
                    : () {
                        audio.click();
                        store.buyPro();
                      },
              ),
            ),
          ],
          ValueListenableBuilder<String?>(
            valueListenable: store.purchaseError,
            builder: (_, err, _) => err == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(err,
                        style: const TextStyle(
                            color: Color(0xFFE08A8A), fontSize: 13),
                        textAlign: TextAlign.center),
                  ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              audio.click();
              store.restore();
            },
            child: Text('Restore purchases',
                style: TextStyle(
                    color: theme.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Consumable tips — pure support, with real store prices.
class _TipsCard extends StatelessWidget {
  final SimonThemeDef theme;
  final StoreService store;
  final SimonAudio audio;
  const _TipsCard(
      {required this.theme, required this.store, required this.audio});

  @override
  Widget build(BuildContext context) {
    final tips = [
      store.coffeeProduct,
      store.chocolateProduct,
    ].whereType<ProductDetails>().toList();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.black.withValues(alpha: 0.35),
        border: Border.all(color: theme.accent, width: 2),
      ),
      child: Column(
        children: [
          Text('Tip the Maker',
              style: TextStyle(
                  color: theme.text,
                  fontWeight: FontWeight.w900,
                  fontSize: 20)),
          const SizedBox(height: 8),
          Text(
            'Simon is free forever. A small tip keeps new games coming!',
            style: TextStyle(color: theme.text, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          if (!store.storeReady)
            Text(
              store.error ?? 'Available after store setup.',
              style: TextStyle(
                  color: theme.muted, fontSize: 13),
              textAlign: TextAlign.center,
            )
          else if (tips.isEmpty)
            Text('Tips coming soon.',
                style: TextStyle(
                    color: theme.muted, fontSize: 13))
          else
            Wrap(
              spacing: 10,
              alignment: WrapAlignment.center,
              children: [
                for (final p in tips)
                  _TipChip(
                    theme: theme,
                    label:
                        '${p.id == StoreService.chocolateId ? '🍫' : '☕'} ${p.price}',
                    onTap: () {
                      audio.click();
                      store.buyTip(p);
                    },
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TipChip extends StatelessWidget {
  final SimonThemeDef theme;
  final String label;
  final VoidCallback onTap;
  const _TipChip(
      {required this.theme, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.black.withValues(alpha: 0.3),
          border:
              Border.all(color: theme.accent.withValues(alpha: 0.6), width: 1.5),
        ),
        child: Text(label,
            style: TextStyle(
                color: theme.text,
                fontWeight: FontWeight.w700,
                fontSize: 14)),
      ),
    );
  }
}
