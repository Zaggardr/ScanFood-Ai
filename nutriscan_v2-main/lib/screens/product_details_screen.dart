import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../models/product.dart';
import 'package:google_fonts/google_fonts.dart';

class ProductDetailsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final Product product =
        ModalRoute.of(context)!.settings.arguments as Product;

    print(
      'Displaying product: ${product.productName ?? 'N/A'}, Brands: ${product.brands ?? 'N/A'}',
    );

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Product Details',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color:
                  Theme.of(context).appBarTheme.foregroundColor ?? Colors.white,
            ),
          ),
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).brightness == Brightness.dark
                      ? Color(0xFF1B5E20)
                      : Color(0xFF2E7D32),
                  Theme.of(context).brightness == Brightness.dark
                      ? Color(0xFF4CAF50)
                      : Color(0xFF81C784),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Nutrition'),
              Tab(text: 'Ingredients'),
              Tab(text: 'KPIs'),
            ],
            labelColor:
                Theme.of(context).appBarTheme.foregroundColor ?? Colors.white,
            unselectedLabelColor:
                (Theme.of(context).appBarTheme.foregroundColor ?? Colors.white)
                    .withOpacity(0.7),
            indicatorColor:
                Theme.of(context).brightness == Brightness.dark
                    ? Color(0xFF66BB6A)
                    : Color(0xFF4CAF50),
            labelStyle: GoogleFonts.poppins(fontSize: 14),
            unselectedLabelStyle: GoogleFonts.poppins(fontSize: 14),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors:
                  Theme.of(context).brightness == Brightness.dark
                      ? [Color(0xFF212121), Color(0xFF424242)]
                      : [Color(0xFFE8F5E9), Color(0xFFFFFFFF)],
            ),
          ),
          child: TabBarView(
            children: [
              _buildOverviewTab(context, product),
              _buildNutritionTab(context, product),
              _buildIngredientsTab(context, product),
              _buildKpiTab(context, product),
            ],
          ),
        ),
      ),
    );
  }

  bool _isValidUrl(String? url) {
    if (url == null || url.isEmpty || url.startsWith('file://')) {
      print('Invalid URL detected: $url');
      return false;
    }
    final isValid =
        Uri.tryParse(url)?.hasScheme == true &&
        (url.startsWith('http://') || url.startsWith('https://'));
    if (!isValid) print('Invalid URL detected: $url');
    return isValid;
  }

  Widget _buildOverviewTab(BuildContext context, Product product) {
    final positives = product.getPositiveAspects();
    final negatives = product.getNegativeAspects();
    final recommendations = product.getRecommendations();
    final additives = product.getAdditives();

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            shadowColor: (Theme.of(context).primaryColor).withOpacity(0.2),
            color: Theme.of(context).cardColor,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child:
                        _isValidUrl(product.imageUrl)
                            ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                product.imageUrl!,
                                width: 150,
                                height: 150,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  print(
                                    'Image load error: $error for URL: ${product.imageUrl}',
                                  );
                                  return const Icon(
                                    Icons.broken_image,
                                    size: 150,
                                    color: Color(0xFF757575),
                                  );
                                },
                              ),
                            )
                            : const Icon(
                              Icons.image_not_supported,
                              size: 150,
                              color: Color(0xFF757575),
                            ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    product.productName ?? 'N/A',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildInfoTile(context, 'Brand', product.brands ?? 'N/A'),
                  _buildInfoTile(
                    context,
                    'Nutri-Score',
                    product.nutriScore?.toUpperCase() ?? 'N/A',
                  ),
                  _buildInfoTile(
                    context,
                    'NOVA Group',
                    product.novaGroup ?? 'N/A',
                  ),
                  _buildInfoTile(
                    context,
                    'Eco-Score',
                    product.ecoScore?.toUpperCase() ?? 'N/A',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            shadowColor: (Theme.of(context).primaryColor).withOpacity(0.2),
            color: Theme.of(context).cardColor,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Positive Aspects',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (positives.isEmpty)
                    Text(
                      'N/A',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    )
                  else
                    ...positives.map(
                      (aspect) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Theme.of(context).primaryColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                aspect,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color:
                                      Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            shadowColor: (Theme.of(context).primaryColor).withOpacity(0.2),
            color: Theme.of(context).cardColor,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Negative Aspects',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (negatives.isEmpty)
                    Text(
                      'N/A',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    )
                  else
                    ...negatives.map(
                      (aspect) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.warning,
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.redAccent
                                      : Color(0xFFF44336),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                aspect,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color:
                                      Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            shadowColor: (Theme.of(context).primaryColor).withOpacity(0.2),
            color: Theme.of(context).cardColor,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recommendations',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (recommendations.isEmpty)
                    Text(
                      'N/A',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    )
                  else
                    ...recommendations.map(
                      (rec) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info,
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.lightBlueAccent
                                      : Color(0xFF2196F3),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                rec,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color:
                                      Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (additives.isNotEmpty)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              shadowColor: (Theme.of(context).primaryColor).withOpacity(0.2),
              color: Theme.of(context).cardColor,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Additives',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...additives.map(
                      (additive) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.label,
                              color:
                                  Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.orangeAccent
                                      : Color(0xFFFF9800),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                additive,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color:
                                      Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              shadowColor: (Theme.of(context).primaryColor).withOpacity(0.2),
              color: Theme.of(context).cardColor,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Additives',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'N/A',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            shadowColor: (Theme.of(context).primaryColor).withOpacity(0.2),
            color: Theme.of(context).cardColor,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall Analysis',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          product.analyze().contains('unhealthy')
                              ? (Theme.of(context).brightness == Brightness.dark
                                  ? Colors.redAccent.withOpacity(0.1)
                                  : Color(0xFFF44336).withOpacity(0.1))
                              : (Theme.of(context).brightness == Brightness.dark
                                  ? Color(0xFF66BB6A).withOpacity(0.1)
                                  : Color(0xFF4CAF50).withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      product.analyze(),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color:
                            product.analyze().contains('unhealthy')
                                ? (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.redAccent
                                    : Color(0xFFF44336))
                                : (Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Color(0xFF66BB6A)
                                    : Color(0xFF4CAF50)),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionTab(BuildContext context, Product product) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        shadowColor: (Theme.of(context).primaryColor).withOpacity(0.2),
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nutrition (per 100g)',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: 8),
              _buildNutritionTile(
                context,
                'Energy',
                product.getEnergy().toStringAsFixed(1),
                'kcal',
              ),
              _buildNutritionTile(
                context,
                'Fat',
                product.getFat().toStringAsFixed(1),
                'g',
              ),
              _buildNutritionTile(
                context,
                'Sugar',
                product.getSugar().toStringAsFixed(1),
                'g',
              ),
              _buildNutritionTile(
                context,
                'Salt',
                product.getSalt().toStringAsFixed(1),
                'g',
              ),
              _buildNutritionTile(
                context,
                'Protein',
                product.getProtein().toStringAsFixed(1),
                'g',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIngredientsTab(BuildContext context, Product product) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        shadowColor: (Theme.of(context).primaryColor).withOpacity(0.2),
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ingredients',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: 8),
              Text(
                product.ingredientsText ?? 'N/A',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Allergens',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: 8),
              Text(
                product.allergens ?? 'N/A',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiTab(BuildContext context, Product product) {
    final energyIndex = product.getEnergyIndex();
    final nutritionalIndex = product.getNutritionalIndex();
    final complianceIndex = product.getComplianceIndex();
    final qualityPercentage = product.getQualityPercentage();

    print('KPI Values:');
    print('Energy Index: $energyIndex');
    print('Nutritional Index: $nutritionalIndex');
    print('Compliance Index: $complianceIndex');
    print('Quality Percentage: $qualityPercentage');

    final clampedEnergyIndex = energyIndex.clamp(0.0, 100.0) / 100;
    final clampedNutritionalIndex = nutritionalIndex.clamp(0.0, 100.0) / 100;
    final clampedComplianceIndex = complianceIndex.clamp(0.0, 100.0) / 100;
    final clampedQualityPercentage = qualityPercentage.clamp(0.0, 100.0) / 100;

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        shadowColor: (Theme.of(context).primaryColor).withOpacity(0.2),
        color: Theme.of(context).cardColor,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Key Performance Indicators',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: 16),
              _buildKpiIndicator(
                context,
                'Energy Index',
                clampedEnergyIndex,
                'Measures energy density (lower is better)',
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.lightBlueAccent
                    : Color(0xFF2196F3),
              ),
              SizedBox(height: 16),
              _buildKpiIndicator(
                context,
                'Nutritional Index',
                clampedNutritionalIndex,
                'Evaluates nutritional balance (sugar, fat, salt)',
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.orangeAccent
                    : Color(0xFFFF9800),
              ),
              SizedBox(height: 16),
              _buildKpiIndicator(
                context,
                'Compliance Index',
                clampedComplianceIndex,
                'Assesses compliance (fewer additives/allergens)',
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.purpleAccent
                    : Color(0xFF9C27B0),
              ),
              SizedBox(height: 24),
              Text(
                'Overall Product Quality',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: 8),
              CircularPercentIndicator(
                radius: 60.0,
                lineWidth: 10.0,
                percent: clampedQualityPercentage,
                center: Text(
                  '${qualityPercentage.toStringAsFixed(1)}%',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                progressColor: Theme.of(context).primaryColor,
                backgroundColor:
                    Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[700]!
                        : Colors.grey[200]!,
                circularStrokeCap: CircularStrokeCap.round,
              ),
              SizedBox(height: 8),
              Text(
                'Weighted average of KPIs',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiIndicator(
    BuildContext context,
    String title,
    double percent,
    String description,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 1,
          child: CircularPercentIndicator(
            radius: 40.0,
            lineWidth: 8.0,
            percent: percent,
            center: Text(
              '${(percent * 100).toStringAsFixed(1)}%',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            progressColor: color,
            backgroundColor:
                Theme.of(context).brightness == Brightness.dark
                    ? Colors.grey[700]!
                    : Colors.grey[200]!,
            circularStrokeCap: CircularStrokeCap.round,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(BuildContext context, String title, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title: ',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionTile(
    BuildContext context,
    String title,
    String value,
    String unit,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$title: ',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          Text(
            '$value $unit',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
}
