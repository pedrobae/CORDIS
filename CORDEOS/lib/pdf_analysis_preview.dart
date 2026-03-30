// ignore_for_file: depend_on_referenced_packages

import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cordeos/models/dtos/pdf_dto.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:cordeos/helpers/pdf_glyph_extractor.dart';

void main() {
  runApp(const PdfAnalysisApp());
}

class PdfAnalysisApp extends StatelessWidget {
  const PdfAnalysisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PDF Analysis Preview',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const PdfAnalysisScreen(),
    );
  }
}

class PdfAnalysisScreen extends StatefulWidget {
  const PdfAnalysisScreen({super.key});

  @override
  State<PdfAnalysisScreen> createState() => _PdfAnalysisScreenState();
}

class _PdfAnalysisScreenState extends State<PdfAnalysisScreen> {
  final List<PdfDocument> _documents = [];
  final List<String> _documentNames = [];
  final Map<String, List<LineData>> _documentData = {};
  final Map<String, DocumentData> _documentDataObjects = {};
  int _selectedDocIndex = 0;
  bool _isLoading = false;
  final Map<String, bool> _showColumnReorderedVersion = {};

  @override
  void dispose() {
    for (var doc in _documents) {
      doc.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPdfFiles() async {
    try {
      setState(() => _isLoading = true);

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        for (var file in result.files) {
          if (file.path != null) {
            await _loadPdfDocument(file.path!, file.name);
          }
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao carregar PDF: $e')));
      }
    }
  }

  Future<void> _loadPdfDocument(String path, String name) async {
    try {
      final bytes = await File(path).readAsBytes();
      final document = PdfDocument(inputBytes: bytes);

      // Extract glyphs per page directly from renderer glyph list
      final Map<int, List<TextGlyph>> pageGlyphs = {};

      for (int i = 0; i < document.pages.count; i++) {
        pageGlyphs[i] = PdfGlyphExtractorHelper.extractPageGlyphs(document, i);
      }

      // Sort glyphs by their vertical position (top)
      for (var pageGlyphList in pageGlyphs.values) {
        pageGlyphList.sort((a, b) {
          return a.bounds.top.compareTo(b.bounds.top);
        });
      }

      final DocumentData documentData = DocumentData.fromGlyphMap(
        pageGlyphs,
        name,
      );
      documentData.searchColumns();

      if (mounted) {
        setState(() {
          _documents.add(document);
          _documentNames.add(name);
          _documentData[name] = documentData.pageLines.values.first;
          _documentDataObjects[name] = documentData;
          _selectedDocIndex = _documents.length - 1;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao processar $name: $e')));
      }
    }
  }

  void _clearAll() {
    setState(() {
      for (var doc in _documents) {
        doc.dispose();
      }
      _documents.clear();
      _documentNames.clear();
      _documentData.clear();
      _documentDataObjects.clear();
      _showColumnReorderedVersion.clear();
      _selectedDocIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDocuments = _documents.isNotEmpty;
    final currentDocName = hasDocuments
        ? _documentNames[_selectedDocIndex]
        : null;
    final currentData = currentDocName != null
        ? _documentData[currentDocName]
        : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Analysis Preview'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          if (hasDocuments)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: _clearAll,
              tooltip: 'Limpar todos',
            ),
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: _pickPdfFiles,
            tooltip: 'Importar PDFs',
          ),
        ],
      ),
      body: !hasDocuments
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.picture_as_pdf,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum PDF carregado',
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _pickPdfFiles,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Importar PDFs'),
                  ),
                ],
              ),
            )
          : Row(
              children: [
                // Document list sidebar
                Container(
                  width: 200,
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: ListView.builder(
                    itemCount: _documentNames.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        title: Text(
                          _documentNames[index],
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: _selectedDocIndex == index
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        selected: _selectedDocIndex == index,
                        selectedTileColor: theme.colorScheme.primaryContainer,
                        onTap: () {
                          setState(() {
                            _selectedDocIndex = index;
                          });
                        },
                      );
                    },
                  ),
                ),
                // Main content
                Expanded(
                  child: Stack(
                    children: [
                      if (currentData != null)
                        _buildAnalysisView(
                          currentData,
                          theme,
                          _documentDataObjects[currentDocName],
                          currentDocName != null
                              ? _showColumnReorderedVersion[currentDocName] ??
                                    false
                              : false,
                          currentDocName != null
                              ? (show) {
                                  setState(() {
                                    _showColumnReorderedVersion[currentDocName] =
                                        show;
                                  });
                                }
                              : null,
                        )
                      else
                        const Center(child: CircularProgressIndicator()),
                      if (_isLoading)
                        Container(
                          color: Colors.black54,
                          child: const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text(
                                  'Processando PDF...',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAnalysisView(
    List<LineData> data,
    ThemeData theme,
    DocumentData? documentData,
    bool showColumnReorderedVersion,
    Function(bool)? onColumnVersionChanged,
  ) {
    // Choose which version to display
    List<LineData> displayData = data;
    bool hasColumnDetection = false;

    if (documentData != null && documentData.pageLinesWithColumns.isNotEmpty) {
      // Check if the first page has column detection
      if (documentData.hasColumns.values.any((hasCol) => hasCol)) {
        hasColumnDetection = true;
        if (showColumnReorderedVersion &&
            documentData.pageLinesWithColumns.values.isNotEmpty) {
          displayData = documentData.pageLinesWithColumns.values.first;
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Version selector toggle
        if (hasColumnDetection)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Visualizando: ${showColumnReorderedVersion ? 'Com Reordenação de Colunas' : 'Sem Reordenação'}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  Switch(
                    value: showColumnReorderedVersion,
                    onChanged: onColumnVersionChanged,
                  ),
                ],
              ),
            ),
          ),
        if (hasColumnDetection) const SizedBox(height: 16),
        // Summary stats
        _buildSummaryCard(displayData, theme),
        const SizedBox(height: 16),

        // Projected bounds visualization
        if (documentData != null && documentData.projectedBounds.isNotEmpty)
          _buildProjectedBoundsCard(documentData, theme),
        if (documentData != null && documentData.projectedBounds.isNotEmpty)
          const SizedBox(height: 16),

        // Average spacing between words chart
        _buildChartCard(
          'Espaçamento Médio Entre Palavras',
          _buildAverageWordSpacingChart(displayData, theme),
          theme,
        ),
        const SizedBox(height: 16),

        // Font Size chart
        _buildChartCard(
          'Tamanho da Fonte por Linha',
          _buildFontSizeChart(displayData, theme),
          theme,
        ),
        const SizedBox(height: 16),

        // Line height chart
        _buildChartCard(
          'Altura por Linha',
          _buildLineHeightChart(displayData, theme),
          theme,
        ),
        const SizedBox(height: 16),

        // Y-position chart
        _buildChartCard(
          'Posição Vertical (Y)',
          _buildYPositionChart(displayData, theme),
          theme,
        ),
        const SizedBox(height: 16),

        // Line spacing chart
        _buildChartCard(
          'Espaçamento Entre Linhas',
          _buildLineSpacingChart(displayData, theme),
          theme,
        ),
        const SizedBox(height: 16),

        // Font style per line chart
        _buildChartCard(
          'Estilo de Fonte por Linha',
          _buildFontStylePerLineChart(displayData, theme),
          theme,
        ),
        const SizedBox(height: 16),

        // Detailed line list
        _buildDetailedLineList(displayData, theme),
      ],
    );
  }

  Widget _buildSummaryCard(List<LineData> data, ThemeData theme) {
    if (data.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Resumo', style: theme.textTheme.titleLarge),
              const Divider(),
              const Text('Nenhum dado disponível'),
            ],
          ),
        ),
      );
    }

    final totalLines = data.length;
    final totalWords = data.fold<int>(
      0,
      (sum, line) => sum + line.pdfWordCount,
    );
    final avgWordsPerLine = totalLines > 0 ? totalWords / totalLines : 0.0;
    final fontSizes = data.map((l) => l.fontSize ?? 0.0).toSet().toList()
      ..sort();
    final avgFontSize = totalLines > 0
        ? data.fold<double>(0, (sum, line) => sum + (line.fontSize ?? 0.0)) /
              totalLines
        : 0.0;
    final emptyLines = data.where((l) => l.text.trim().isEmpty).length;

    // Calculate average word length
    final totalChars = data.fold<int>(
      0,
      (sum, line) =>
          sum +
          line.wordList!.fold<int>(0, (wSum, word) => wSum + word.text.length),
    );
    final avgWordLength = totalWords > 0 ? totalChars / totalWords : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resumo', style: theme.textTheme.titleLarge),
            const Divider(),
            _statRow('Total de Linhas:', totalLines.toString()),
            _statRow('Linhas Vazias:', emptyLines.toString()),
            _statRow('Total de Palavras:', totalWords.toString()),
            _statRow(
              'Média de Palavras/Linha:',
              avgWordsPerLine.toStringAsFixed(2),
            ),
            _statRow(
              'Comprimento Médio de Palavra:',
              avgWordLength.toStringAsFixed(2),
            ),
            _statRow('Tamanho de Fonte Médio:', avgFontSize.toStringAsFixed(2)),
            _statRow(
              'Tamanhos de Fonte:',
              fontSizes.map((f) => (f).toStringAsFixed(1)).join(', '),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildProjectedBoundsCard(DocumentData documentData, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Projeção de Limites', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: CustomPaint(
                painter: ProjectedBoundsPainter(documentData.projectedBounds),
                size: Size.infinite,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            SizedBox(height: 200, child: chart),
          ],
        ),
      ),
    );
  }

  Widget _buildAverageWordSpacingChart(List<LineData> data, ThemeData theme) {
    if (data.isEmpty) {
      return const Center(child: Text('Dados insuficientes'));
    }

    final spots = data.asMap().entries.map((entry) {
      final avgSpacing = _averageSpacingForLine(entry.value);
      return FlSpot(entry.key.toDouble() + 1, avgSpacing);
    }).toList();

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: theme.colorScheme.secondary,
            barWidth: 2,
            dotData: const FlDotData(show: false),
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: const Text('Número da Linha'),
            sideTitles: SideTitles(showTitles: true, reservedSize: 30),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        gridData: const FlGridData(show: true),
      ),
    );
  }

  double _averageSpacingForLine(LineData line) {
    if (line.avgSpaceBetweenWords != null) {
      return line.avgSpaceBetweenWords!.toDouble();
    }

    final words = line.wordList!;
    if (words.length < 2) {
      line.avgSpaceBetweenWords ??= 0;
      return 0;
    }

    double totalSpacing = 0;
    for (int i = 0; i < words.length - 1; i++) {
      final gap = max(0.0, words[i + 1].bounds.left - words[i].bounds.right);
      totalSpacing += gap;
    }

    final avg = totalSpacing / (words.length - 1);
    line.avgSpaceBetweenWords = avg.round();
    return avg;
  }

  Widget _buildFontSizeChart(List<LineData> data, ThemeData theme) {
    if (data.isEmpty) {
      return const Center(child: Text('Dados insuficientes'));
    }

    final spots = data
        .asMap()
        .entries
        .map(
          (e) => FlSpot(
            e.key.toDouble() + 1,
            (e.value.fontSize ?? 0.0).toDouble(),
          ),
        )
        .toList();

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: theme.colorScheme.tertiary,
            barWidth: 2,
            dotData: const FlDotData(show: false),
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: const Text('Número da Linha'),
            sideTitles: SideTitles(showTitles: true, reservedSize: 30),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        gridData: const FlGridData(show: true),
      ),
    );
  }

  Widget _buildLineHeightChart(List<LineData> data, ThemeData theme) {
    if (data.isEmpty) {
      return const Center(child: Text('Dados insuficientes'));
    }

    final spots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble() + 1, e.value.bounds!.height))
        .toList();

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: theme.colorScheme.tertiary,
            barWidth: 2,
            dotData: const FlDotData(show: false),
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: const Text('Número da Linha'),
            sideTitles: SideTitles(showTitles: true, reservedSize: 30),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        gridData: const FlGridData(show: true),
      ),
    );
  }

  Widget _buildYPositionChart(List<LineData> data, ThemeData theme) {
    if (data.isEmpty) {
      return const Center(child: Text('Dados insuficientes'));
    }

    final spots = data
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble() + 1, e.value.bounds!.top))
        .toList();

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: Colors.orange,
            barWidth: 2,
            dotData: const FlDotData(show: false),
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: const Text('Número da Linha'),
            sideTitles: SideTitles(showTitles: true, reservedSize: 30),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        gridData: const FlGridData(show: true),
      ),
    );
  }

  Widget _buildLineSpacingChart(List<LineData> data, ThemeData theme) {
    if (data.length < 2) {
      return const Center(child: Text('Dados insuficientes'));
    }

    final spacings = <FlSpot>[];
    final gaps = <double>[];
    for (int i = 1; i < data.length; i++) {
      // Calculate gap between end of previous line and start of current line
      final prevBottom = data[i - 1].bounds!.top + data[i - 1].bounds!.height;
      final currentTop = data[i].bounds!.top;
      final gap = currentTop - prevBottom;
      spacings.add(FlSpot(i.toDouble(), gap));
      gaps.add(gap);
    }

    final double mean = gaps.isEmpty
        ? 0
        : gaps.reduce((a, b) => a + b) / gaps.length;
    final double variance = gaps.isEmpty
        ? 0
        : gaps.fold<double>(0, (sum, g) => sum + (g - mean) * (g - mean)) /
              gaps.length;
    final double stdDev = sqrt(variance);

    FlSpot ref(double y) =>
        FlSpot(spacings.first.x, y); // helper for horizontal reference
    FlSpot refEnd(double y) => FlSpot(spacings.last.x, y);

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spacings,
            isCurved: false,
            color: Colors.purple,
            barWidth: 2,
            dotData: const FlDotData(show: false),
          ),
          // Mean spacing reference line
          LineChartBarData(
            spots: [ref(mean), refEnd(mean)],
            isCurved: false,
            color: theme.colorScheme.outline,
            barWidth: 1,
            dotData: const FlDotData(show: false),
          ),
          // Mean + 1 std deviation reference line
          LineChartBarData(
            spots: [ref(mean + stdDev), refEnd(mean + stdDev)],
            isCurved: false,
            color: Colors.redAccent,
            barWidth: 1,
            dashArray: [6, 4],
            dotData: const FlDotData(show: false),
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: const Text('Número da Linha'),
            sideTitles: SideTitles(showTitles: true, reservedSize: 30),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: true),
        gridData: const FlGridData(show: true),
      ),
    );
  }

  Widget _buildFontStylePerLineChart(List<LineData> data, ThemeData theme) {
    if (data.isEmpty) {
      return const Center(child: Text('Dados insuficientes'));
    }

    // Map font styles to numeric values for visualization
    final styleToValue = {
      PdfFontStyle.regular: 1.0,
      PdfFontStyle.bold: 2.0,
      PdfFontStyle.italic: 3.0,
      PdfFontStyle.strikethrough: 4.0,
      PdfFontStyle.underline: 5.0,
    };

    final spots = data.asMap().entries.map((entry) {
      final styleName = entry.value.fontStyle;
      final value = styleToValue[styleName?.lastOrNull] ?? 0.5;
      return FlSpot(entry.key.toDouble() + 1, value);
    }).toList();

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: false,
            color: Colors.teal,
            barWidth: 2,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                // Use spot.x as the data index (safer than using index parameter)
                final dataIndex = spot.x.toInt() - 1;
                if (dataIndex < 0 || dataIndex >= data.length) {
                  return FlDotCirclePainter(
                    radius: 3,
                    color: Colors.grey,
                    strokeWidth: 1,
                    strokeColor: Colors.white,
                  );
                }
                final style = data[dataIndex].fontStyle?.lastOrNull;
                Color dotColor = Colors.grey;
                if (style == PdfFontStyle.bold) {
                  dotColor = Colors.red;
                } else if (style == PdfFontStyle.italic) {
                  dotColor = Colors.blue;
                } else if (style == PdfFontStyle.strikethrough) {
                  dotColor = Colors.purple;
                } else if (style == PdfFontStyle.underline) {
                  dotColor = Colors.orange;
                } else if (style == PdfFontStyle.regular) {
                  dotColor = Colors.green;
                } else {
                  dotColor = Colors.grey;
                }
                return FlDotCirclePainter(
                  radius: 3,
                  color: dotColor,
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                );
              },
            ),
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                switch (value.toInt()) {
                  case 1:
                    return const Text('Regular', style: TextStyle(fontSize: 9));
                  case 2:
                    return const Text('Bold', style: TextStyle(fontSize: 9));
                  case 3:
                    return const Text('Italic', style: TextStyle(fontSize: 9));
                  case 4:
                    return const Text(
                      'Strikethrough',
                      style: TextStyle(fontSize: 9),
                    );
                  case 5:
                    return const Text(
                      'Underline',
                      style: TextStyle(fontSize: 9),
                    );
                  default:
                    return const Text('');
                }
              },
            ),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: const Text('Número da Linha'),
            sideTitles: SideTitles(showTitles: true, reservedSize: 30),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        minY: 0.5,
        maxY: 5,
        borderData: FlBorderData(show: true),
        gridData: const FlGridData(show: true),
      ),
    );
  }

  Widget _buildDetailedLineList(List<LineData> data, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Detalhes das Linhas', style: theme.textTheme.titleMedium),
            const Divider(),
            ...data.take(50).map((line) => _buildLineDetail(line, theme)),
            if (data.length > 50)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  '... e mais ${data.length - 50} linhas',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineDetail(LineData line, ThemeData theme) {
    return ExpansionTile(
      title: Text(
        'Linha ${line.lineIndex + 1}',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        line.text.length > 50 ? '${line.text.substring(0, 50)}...' : line.text,
        style: const TextStyle(fontSize: 11),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Texto: ${line.text}', style: const TextStyle(fontSize: 11)),
              Text('Tamanho Fonte: ${line.fontSize?.toStringAsFixed(2)}'),
              Text('Estilo: ${line.fontStyle.toString().split('.').last}'),
              Text('Palavras: ${line.wordCount}'),
              Text(
                'Bounds: x=${line.bounds!.left.toStringAsFixed(1)}, '
                'y=${line.bounds!.top.toStringAsFixed(1)}, '
                'w=${line.bounds!.width.toStringAsFixed(1)}, '
                'h=${line.bounds!.height.toStringAsFixed(1)}',
              ),
              const Divider(),
              Text(
                'Palavras:',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 16,
                  dataRowMinHeight: 28,
                  dataRowMaxHeight: 36,
                  headingRowHeight: 32,
                  columns: const [
                    DataColumn(
                      label: Text(
                        'Texto',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Tamanho',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text(
                        'Largura',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text(
                        'Altura',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text(
                        'X',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text(
                        'Y',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      numeric: true,
                    ),
                    DataColumn(
                      label: Text(
                        'Estilo',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                  rows: line.wordList!
                      .map(
                        (word) => DataRow(
                          cells: [
                            DataCell(
                              Text(
                                word.text,
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                            DataCell(
                              Text(
                                word.fontSize?.toStringAsFixed(1) ?? '',
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                            DataCell(
                              Text(
                                word.bounds.width.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                            DataCell(
                              Text(
                                word.bounds.height.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                            DataCell(
                              Text(
                                word.bounds.left.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                            DataCell(
                              Text(
                                word.bounds.top.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                            DataCell(
                              Text(
                                word.fontStyle.toString().split('.').last,
                                style: const TextStyle(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ProjectedBoundsPainter extends CustomPainter {
  final Map<int, List<double>> projectedBounds;

  ProjectedBoundsPainter(this.projectedBounds);

  @override
  void paint(Canvas canvas, Size size) {
    if (projectedBounds.isEmpty) {
      return;
    }

    final bounds = projectedBounds.values.first; // Get first page bounds
    if (bounds.isEmpty) return;

    // Get min and max values for scaling
    final minBound = bounds.reduce((a, b) => a < b ? a : b);
    final maxBound = bounds.reduce((a, b) => a > b ? a : b);
    final range = maxBound - minBound;
    final padding = 20.0;
    final availableWidth = size.width - (padding * 2);

    // Paint background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.grey.shade100,
    );

    // Paint intervals
    for (int i = 0; i < bounds.length - 1; i += 2) {
      final startNorm = ((bounds[i] - minBound) / range) * availableWidth;
      final endNorm = ((bounds[i + 1] - minBound) / range) * availableWidth;

      final x1 = padding + startNorm;
      final x2 = padding + endNorm;

      // Draw interval rectangle
      canvas.drawRect(
        Rect.fromLTWH(x1, size.height / 4, x2 - x1, size.height / 2),
        Paint()..color = Colors.blue.withAlpha((0.6 * 255).toInt()),
      );

      // Draw labels
      final textPainter = TextPainter(
        text: TextSpan(
          text: bounds[i].toStringAsFixed(0),
          style: const TextStyle(color: Colors.black, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x1 - textPainter.width / 2, 5));

      final endTextPainter = TextPainter(
        text: TextSpan(
          text: bounds[i + 1].toStringAsFixed(0),
          style: const TextStyle(color: Colors.black, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      );
      endTextPainter.layout();
      endTextPainter.paint(
        canvas,
        Offset(x2 - endTextPainter.width / 2, size.height - 20),
      );
    }

    // Draw axis line
    canvas.drawLine(
      Offset(padding, size.height / 2),
      Offset(size.width - padding, size.height / 2),
      Paint()
        ..color = Colors.grey
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
