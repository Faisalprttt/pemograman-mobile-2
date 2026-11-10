import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  runApp(const SubnetApp());
}

const _ink = Color(0xFF172B2A);
const _muted = Color(0xFF71817D);
const _canvas = Color(0xFFF3F6F4);
const _green = Color(0xFF167A68);
const _mint = Color(0xFFBDE8D8);
const _orange = Color(0xFFFFB66D);

class SubnetApp extends StatelessWidget {
  const SubnetApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: _green,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: _canvas,
      useMaterial3: true,
    );

    return MaterialApp(
      title: 'IP & Subnetting Calculator',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        textTheme: GoogleFonts.oswaldTextTheme(base.textTheme)
            .apply(bodyColor: _ink, displayColor: _ink),
        appBarTheme: const AppBarTheme(
          backgroundColor: _canvas,
          foregroundColor: _ink,
          elevation: 0,
        ),
      ),
      home: const SubnetCalculatorPage(),
    );
  }
}

class SubnetCalculatorPage extends StatefulWidget {
  const SubnetCalculatorPage({super.key});

  @override
  State<SubnetCalculatorPage> createState() => _SubnetCalculatorPageState();
}

class _SubnetCalculatorPageState extends State<SubnetCalculatorPage> {
  final _ipController = TextEditingController(text: '192.168.1.10');
  final _detailSwiperController = CardSwiperController();
  int _prefix = 24;
  int _summaryPage = 0;
  int _detailCard = 0;
  SubnetResult? _result;
  String? _error;

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  @override
  void dispose() {
    _ipController.dispose();
    unawaited(_detailSwiperController.dispose());
    super.dispose();
  }

  void _calculate() {
    final ip = _parseIpv4(_ipController.text.trim());
    if (ip == null) {
      setState(() {
        _result = null;
        _error = 'Masukkan alamat IPv4 yang valid, contoh: 192.168.1.10';
      });
      return;
    }

    final mask = _prefix == 0 ? 0 : (0xFFFFFFFF << (32 - _prefix)) & 0xFFFFFFFF;
    final network = ip & mask;
    final broadcast = network | (~mask & 0xFFFFFFFF);
    final hostCount = switch (_prefix) {
      32 => 1,
      31 => 2,
      _ => broadcast - network - 1,
    };
    final firstHost = _prefix >= 31 ? network : network + 1;
    final lastHost = _prefix >= 31 ? broadcast : broadcast - 1;

    setState(() {
      _result = SubnetResult(
        ipAddress: _formatIpv4(ip),
        network: _formatIpv4(network),
        broadcast: _formatIpv4(broadcast),
        subnetMask: _formatIpv4(mask),
        wildcard: _formatIpv4(~mask & 0xFFFFFFFF),
        firstHost: _formatIpv4(firstHost),
        lastHost: _formatIpv4(lastHost),
        hostCount: hostCount,
        prefix: _prefix,
        addressType: _addressType(ip),
      );
      _error = null;
    });
  }

  Future<void> _copyResults() async {
    final result = _result;
    if (result == null) return;

    await Clipboard.setData(ClipboardData(text: result.asText));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Hasil subnet disalin ke clipboard'),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBrand(),
                  const SizedBox(height: 30),
                  Text(
                    'IP & SUBNETTING',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 33,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Network utility untuk membaca detail jaringan IPv4.',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: _muted, fontSize: 14),
                  ),
                  const SizedBox(height: 22),
                  _buildCalculatorCard(),
                  const SizedBox(height: 27),
                  _buildResults(),
                  const SizedBox(height: 25),
                  Center(
                    child: Text(
                      'DIBUAT UNTUK MEMUDAHKAN ANALISIS JARINGAN',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: _muted,
                        fontSize: 10,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrand() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _ink,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.hub_rounded, color: _mint, size: 23),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NET / LENS',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                ),
              ),
              Text(
                'NETWORK TOOLKIT',
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: _muted, fontSize: 9, letterSpacing: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _mint.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: _green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'IPV4 READY',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: _green,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalculatorCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _ink,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, color: _mint, size: 19),
              const SizedBox(width: 8),
              Text(
                'KONFIGURASI JARINGAN',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: _mint,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 19),
          Text(
            'Alamat IP',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 7),
          TextField(
            key: const ValueKey('ip-address-field'),
            controller: _ipController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _calculate(),
            style: GoogleFonts.oswald(
              color: Colors.white,
              fontSize: 19,
              letterSpacing: 0.5,
            ),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: InputDecoration(
              hintText: '192.168.1.10',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.09),
              prefixIcon: Icon(
                Icons.language_rounded,
                color: Colors.white.withValues(alpha: 0.72),
                size: 20,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 15,
                horizontal: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.1),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _mint, width: 1.3),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  'PREFIX SUBNET',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.68),
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Container(
                height: 44,
                padding: const EdgeInsets.only(left: 14, right: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    key: const ValueKey('prefix-dropdown'),
                    value: _prefix,
                    dropdownColor: _ink,
                    iconEnabledColor: _mint,
                    style: GoogleFonts.oswald(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    items: List.generate(
                      33,
                      (index) => DropdownMenuItem(
                        value: index,
                        child: Text('/$index'),
                      ),
                    ),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _prefix = value);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 17),
          SizedBox(
            width: double.infinity,
            height: 51,
            child: FilledButton.icon(
              key: const ValueKey('calculate-button'),
              onPressed: _calculate,
              icon: const Icon(Icons.bolt_rounded, size: 20),
              label: Text(
                'HITUNG SUBNET',
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 1),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: _orange,
                foregroundColor: _ink,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(
              _error!,
              key: const ValueKey('validation-error'),
              style: const TextStyle(color: Color(0xFFFFC5B9), fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResults() {
    final result = _result;
    if (result == null) return const SizedBox.shrink();

    final summaries = [
      _SummaryCardData(
        label: 'NETWORK ADDRESS',
        value: '${result.network}/${result.prefix}',
        detailLabel: 'IP YANG DIHITUNG',
        detailValue: result.ipAddress,
        icon: Icons.hub_rounded,
        background: _green,
        foreground: Colors.white,
        accent: _mint,
      ),
      _SummaryCardData(
        label: 'BROADCAST',
        value: result.broadcast,
        detailLabel: 'RENTANG HOST',
        detailValue: result.hostRange,
        icon: Icons.campaign_rounded,
        background: _ink,
        foreground: Colors.white,
        accent: _mint,
      ),
      _SummaryCardData(
        label: 'SUBNET MASK',
        value: result.subnetMask,
        detailLabel: 'WILDCARD',
        detailValue: result.wildcard,
        icon: Icons.layers_rounded,
        background: const Color(0xFFE1F1E9),
        foreground: _ink,
        accent: _green,
      ),
    ];
    final details = _buildDetailCards(result);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HASIL ANALISIS',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: _green,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Ringkasan subnet kamu',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontSize: 21, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Salin hasil',
              onPressed: _copyResults,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _green,
              ),
              icon: const Icon(Icons.content_copy_rounded, size: 19),
            ),
          ],
        ),
        const SizedBox(height: 13),
        CarouselSlider.builder(
          key: const ValueKey('subnet-summary-carousel'),
          itemCount: summaries.length,
          itemBuilder: (context, index, realIndex) =>
              _buildSummaryCard(summaries[index]),
          options: CarouselOptions(
            height: 202,
            viewportFraction: 0.9,
            enlargeCenterPage: true,
            enlargeFactor: 0.06,
            enableInfiniteScroll: false,
            onPageChanged: (index, reason) {
              setState(() => _summaryPage = index);
            },
          ),
        ),
        const SizedBox(height: 8),
        _buildPageIndicator(_summaryPage, summaries.length),
        const SizedBox(height: 25),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'DETAIL JARINGAN',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: _green,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Geser kartu untuk menjelajah',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Text(
              '${_detailCard + 1} / ${details.length}',
              key: const ValueKey('detail-card-indicator'),
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: _muted, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 9),
        SizedBox(
          height: 264,
          child: CardSwiper(
            key: const ValueKey('network-detail-swiper'),
            controller: _detailSwiperController,
            cardsCount: details.length,
            numberOfCardsDisplayed: 2,
            isLoop: true,
            maxAngle: 8,
            threshold: 35,
            scale: 0.94,
            backCardOffset: const Offset(0, 13),
            padding: const EdgeInsets.fromLTRB(2, 8, 2, 21),
            allowedSwipeDirection: const AllowedSwipeDirection.symmetric(
              horizontal: true,
            ),
            onSwipe: (previousIndex, currentIndex, direction) {
              if (currentIndex != null) {
                setState(() => _detailCard = currentIndex);
              }
              return true;
            },
            cardBuilder: (context, index, horizontalOffset, verticalOffset) =>
                _buildDetailCard(details[index], index),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(_SummaryCardData data) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 15),
      decoration: BoxDecoration(
        color: data.background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: data.foreground == Colors.white
              ? Colors.white.withValues(alpha: 0.08)
              : _green.withValues(alpha: 0.1),
        ),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(data.icon, color: data.accent, size: 17),
              const SizedBox(width: 7),
              Text(
                data.label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: data.foreground.withValues(alpha: 0.75),
                  fontSize: 10,
                  letterSpacing: 1.1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: data.foreground.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'IPV4',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: data.foreground,
                    fontSize: 9,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            data.value,
            key: data.label == 'NETWORK ADDRESS'
                ? const ValueKey('network-result')
                : null,
            style: GoogleFonts.oswald(
              color: data.foreground,
              fontSize: 26,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.4,
            ),
          ),
          const Spacer(),
          Divider(color: data.foreground.withValues(alpha: 0.16), height: 16),
          Row(
            children: [
              Icon(Icons.arrow_forward_rounded, color: data.accent, size: 16),
              const SizedBox(width: 6),
              Expanded(child: _buildSummaryDetail(data)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryDetail(_SummaryCardData data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data.detailLabel,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: data.foreground.withValues(alpha: 0.68),
            fontSize: 9,
            letterSpacing: 0.8,
          ),
        ),
        Text(
          data.detailValue,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.oswald(
            color: data.foreground,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildPageIndicator(int activeIndex, int count) {
    return Row(
      key: ValueKey('summary-page-indicator-$activeIndex'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final isActive = index == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: isActive ? 19 : 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: isActive ? _green : _green.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }

  List<_DetailCardData> _buildDetailCards(SubnetResult result) {
    return [
      _DetailCardData(
        eyebrow: '01 / IDENTITAS',
        title: 'Alamat jaringan',
        icon: Icons.router_rounded,
        rows: [
          _DetailValue('IP ADDRESS', result.ipAddress),
          _DetailValue('NETWORK', '${result.network}/${result.prefix}'),
          _DetailValue('TIPE ALAMAT', result.addressType),
        ],
      ),
      _DetailCardData(
        eyebrow: '02 / KONFIGURASI',
        title: 'Subnet & mask',
        icon: Icons.settings_ethernet_rounded,
        rows: [
          _DetailValue('PREFIX', '/${result.prefix}'),
          _DetailValue('SUBNET MASK', result.subnetMask),
          _DetailValue('WILDCARD', result.wildcard),
        ],
      ),
      _DetailCardData(
        eyebrow: '03 / KAPASITAS',
        title: 'Rentang host',
        icon: Icons.devices_rounded,
        rows: [
          _DetailValue('HOST PERTAMA', result.firstHost),
          _DetailValue('HOST TERAKHIR', result.lastHost),
          _DetailValue('HOST TERSEDIA', _formatCount(result.hostCount)),
        ],
      ),
    ];
  }

  Widget _buildDetailCard(_DetailCardData data, int index) {
    return Container(
      key: ValueKey('detail-card-$index'),
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(color: const Color(0xFFE4ECE7)),
        boxShadow: [
          BoxShadow(
            color: _ink.withValues(alpha: 0.1),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: _mint.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(data.icon, color: _green, size: 19),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.eyebrow,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _muted,
                      fontSize: 9,
                      letterSpacing: 0.8,
                    ),
                  ),
                  Text(
                    data.title,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontSize: 17, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...data.rows.map(
            (row) => Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFE9EFEC))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        row.label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: _muted,
                          fontSize: 9,
                          letterSpacing: 0.55,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        row.value,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.oswald(
                          color: _ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCardData {
  const _SummaryCardData({
    required this.label,
    required this.value,
    required this.detailLabel,
    required this.detailValue,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.accent,
  });

  final String label;
  final String value;
  final String detailLabel;
  final String detailValue;
  final IconData icon;
  final Color background;
  final Color foreground;
  final Color accent;
}

class _DetailCardData {
  const _DetailCardData({
    required this.eyebrow,
    required this.title,
    required this.icon,
    required this.rows,
  });

  final String eyebrow;
  final String title;
  final IconData icon;
  final List<_DetailValue> rows;
}

class _DetailValue {
  const _DetailValue(this.label, this.value);

  final String label;
  final String value;
}

class SubnetResult {
  const SubnetResult({
    required this.ipAddress,
    required this.network,
    required this.broadcast,
    required this.subnetMask,
    required this.wildcard,
    required this.firstHost,
    required this.lastHost,
    required this.hostCount,
    required this.prefix,
    required this.addressType,
  });

  final String ipAddress;
  final String network;
  final String broadcast;
  final String subnetMask;
  final String wildcard;
  final String firstHost;
  final String lastHost;
  final int hostCount;
  final int prefix;
  final String addressType;

  String get hostRange => '$firstHost – $lastHost';

  String get asText =>
      '''
IP Address: $ipAddress
Network: $network/$prefix
Subnet Mask: $subnetMask
Wildcard: $wildcard
Broadcast: $broadcast
Host Range: $hostRange
Usable Hosts: $hostCount
Address Type: $addressType''';
}

int? _parseIpv4(String value) {
  final parts = value.split('.');
  if (parts.length != 4) return null;

  var address = 0;
  for (final part in parts) {
    if (part.isEmpty || part.length > 3) return null;
    final octet = int.tryParse(part);
    if (octet == null || octet < 0 || octet > 255) return null;
    address = (address << 8) | octet;
  }
  return address;
}

String _formatIpv4(int address) {
  return [
    (address >> 24) & 0xFF,
    (address >> 16) & 0xFF,
    (address >> 8) & 0xFF,
    address & 0xFF,
  ].join('.');
}

String _addressType(int address) {
  final first = (address >> 24) & 0xFF;
  final second = (address >> 16) & 0xFF;
  if (first == 10 ||
      (first == 172 && second >= 16 && second <= 31) ||
      (first == 192 && second == 168)) {
    return 'Private';
  }
  if (first == 127) return 'Loopback';
  if (first == 169 && second == 254) return 'Link-local';
  if (first >= 224 && first <= 239) return 'Multicast';
  if (first == 0 || first >= 240) return 'Reserved';
  return 'Public';
}

String _formatCount(int count) {
  final digits = count.toString();
  final output = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) output.write('.');
    output.write(digits[index]);
  }
  return output.toString();
}
