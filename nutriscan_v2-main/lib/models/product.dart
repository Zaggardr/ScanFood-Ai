class Product {
  final String? productName;
  final String? brands;
  final String? ingredientsText;
  final String? allergens;
  final String? imageUrl;
  final double? energy;
  final double? fat;
  final double? sugar;
  final double? salt;
  final double? protein;
  final double? fiber;
  final String? nutriScore;
  final String? novaGroup;
  final String? ecoScore;
  final List<String>? additives;

  Product({
    this.productName,
    this.brands,
    this.ingredientsText,
    this.allergens,
    this.imageUrl,
    this.energy,
    this.fat,
    this.sugar,
    this.salt,
    this.protein,
    this.fiber,
    this.nutriScore,
    this.novaGroup,
    this.ecoScore,
    this.additives,
  });

  factory Product.fromFirestore(Map<String, dynamic> data) {
    bool isValidUrl(String? url) {
      if (url == null || url.isEmpty) return false;
      return Uri.tryParse(url)?.hasScheme == true &&
          (url.startsWith('http://') || url.startsWith('https://'));
    }

    return Product(
      productName: data['productName']?.toString(),
      brands: data['brands']?.toString(),
      ingredientsText: data['ingredientsText']?.toString(),
      allergens: data['allergens']?.toString(),
      imageUrl:
          isValidUrl(data['imageUrl']) ? data['imageUrl']?.toString() : null,
      energy: (data['energy'] as num?)?.toDouble(),
      fat: (data['fat'] as num?)?.toDouble(),
      sugar: (data['sugar'] as num?)?.toDouble(),
      salt: (data['salt'] as num?)?.toDouble(),
      protein: (data['protein'] as num?)?.toDouble(),
      fiber: (data['fiber'] as num?)?.toDouble(),
      nutriScore: data['nutriScore']?.toString(),
      novaGroup: data['novaGroup']?.toString(),
      ecoScore: data['ecoScore']?.toString(),
      additives:
          data['additives'] is List
              ? List<String>.from(data['additives'])
              : null,
    );
  }

  get recommendations => null;

  double getEnergy() => energy ?? 0.0;
  double getFat() => fat ?? 0.0;
  double getSugar() => sugar ?? 0.0;
  double getSalt() => salt ?? 0.0;
  double getProtein() => protein ?? 0.0;
  double getFiber() => fiber ?? 0.0;

  List<String> getAdditives() {
    if (ingredientsText == null || ingredientsText!.isEmpty) {
      return additives ?? [];
    }

    // Si les additifs sont déjà fournis (par ex. via Open Food Facts), les utiliser
    if (additives != null && (additives?.isNotEmpty ?? false)) {
      return additives!;
    }

    // Détection des additifs via expressions régulières et mots-clés
    final RegExp additivePattern = RegExp(
      r'\bE\d{3,4}(?:\w)?\b',
      caseSensitive: false,
    );
    final matches = additivePattern.allMatches(ingredientsText!.toLowerCase());
    List<String> detectedAdditives =
        matches.map((match) => match.group(0)!).toList();

    // Liste des additifs et conservateurs courants
    final commonAdditives = [
      'monosodium glutamate',
      'aspartame',
      'sodium benzoate',
      'potassium sorbate',
      'calcium propionate',
      'sodium nitrate',
      'sodium nitrite',
      'sorbic acid',
      'benzoic acid',
      'calcium disodium edta',
    ];

    for (var additive in commonAdditives) {
      if (ingredientsText!.toLowerCase().contains(additive)) {
        detectedAdditives.add(additive);
      }
    }

    return detectedAdditives.isNotEmpty ? detectedAdditives : [];
  }

  Map<String, int> analyzeIngredients() {
    if (ingredientsText == null || ingredientsText!.isEmpty) {
      return {'has_gluten': 0, 'has_soy': 0, 'has_preservatives': 0};
    }

    final text = ingredientsText!.toLowerCase();
    int hasGluten = 0;
    int hasSoy = 0;
    int hasPreservatives = 0;

    // Mots-clés pour détecter les ingrédients
    const glutenKeywords = [
      'wheat',
      'gluten',
      'barley',
      'rye',
      'malt',
      'flour',
    ];
    const soyKeywords = ['soy', 'soya', 'soybean', 'tofu', 'lecithin'];
    const preservativeKeywords = [
      'sodium benzoate',
      'potassium sorbate',
      'sorbic acid',
      'benzoic acid',
      'nitrate',
      'nitrite',
      'sulfite',
      'calcium disodium edta',
    ];

    // Détection des ingrédients
    for (var keyword in glutenKeywords) {
      if (text.contains(keyword)) {
        hasGluten = 1;
        break;
      }
    }
    for (var keyword in soyKeywords) {
      if (text.contains(keyword)) {
        hasSoy = 1;
        break;
      }
    }
    for (var keyword in preservativeKeywords) {
      if (text.contains(keyword)) {
        hasPreservatives = 1;
        break;
      }
    }

    return {
      'has_gluten': hasGluten,
      'has_soy': hasSoy,
      'has_preservatives': hasPreservatives,
    };
  }

  double getEnergyIndex() {
    final energyVal = getEnergy();
    if (energyVal <= 0) return 100.0;
    return (1 - (energyVal / 8400)) * 100;
  }

  double getNutritionalIndex() {
    final sugarVal = getSugar();
    final fatVal = getFat();
    final saltVal = getSalt();
    final fiberVal = getFiber();
    double sugarScore = sugarVal > 10 ? (1 - (sugarVal / 100)) : 1.0;
    double fatScore = fatVal > 20 ? (1 - (fatVal / 100)) : 1.0;
    double saltScore = saltVal > 2 ? (1 - (saltVal / 10)) : 1.0;
    double fiberScore = fiberVal > 0 ? (fiberVal / 10).clamp(0, 1) : 0.0;
    return ((sugarScore + fatScore + saltScore + fiberScore) / 4) * 100;
  }

  double getComplianceIndex() {
    double complianceScore = 100.0;
    if (allergens != null && (allergens?.isNotEmpty ?? false)) {
      complianceScore -= 20;
    }
    if (novaGroup != null && novaGroup == '4') {
      complianceScore -= 20;
    }
    final additivesList = getAdditives();
    if (additivesList.isNotEmpty) {
      complianceScore -= 10 * additivesList.length.clamp(1, 5);
    }
    return complianceScore.clamp(0, 100);
  }

  double getQualityPercentage() {
    return (getEnergyIndex() * 0.3 +
            getNutritionalIndex() * 0.4 +
            getComplianceIndex() * 0.3)
        .clamp(0, 100);
  }

  String analyze() {
    final quality = getQualityPercentage();
    final ingredientAnalysis = analyzeIngredients();
    String analysis = '';

    if (quality >= 70) {
      analysis = "This product is generally healthy.";
    } else if (quality >= 50) {
      analysis = "This product is moderately healthy.";
    } else {
      analysis = "This product may be unhealthy.";
    }

    if (ingredientAnalysis['has_gluten'] == 1) {
      analysis += "\nContains gluten.";
    }
    if (ingredientAnalysis['has_soy'] == 1) {
      analysis += "\nContains soy.";
    }
    if (ingredientAnalysis['has_preservatives'] == 1) {
      analysis += "\nContains preservatives.";
    }

    return analysis;
  }

  List<String> getPositiveAspects() {
    List<String> positives = [];
    if (getSugar() < 5) {
      positives.add("Low sugar content (${getSugar()}g per 100g)");
    }
    if (getFat() < 5) {
      positives.add("Low fat content (${getFat()}g per 100g)");
    }
    if (getSalt() < 0.5) {
      positives.add("Low salt content (${getSalt()}g per 100g)");
    }
    if (getProtein() > 10) {
      positives.add("High protein content (${getProtein()}g per 100g)");
    }
    if (getFiber() > 5) {
      positives.add("High fiber content (${getFiber()}g per 100g)");
    }
    if (nutriScore != null && ['a', 'b'].contains(nutriScore!.toLowerCase())) {
      positives.add("Good Nutri-Score (${nutriScore!.toUpperCase()})");
    }
    if (novaGroup != null && ['1', '2'].contains(novaGroup)) {
      positives.add("Low processing level (NOVA Group $novaGroup)");
    }
    if (ecoScore != null && ['a', 'b'].contains(ecoScore!.toLowerCase())) {
      positives.add("Eco-friendly (Eco-Score ${ecoScore!.toUpperCase()})");
    }
    if (allergens == null || (allergens?.isEmpty ?? true)) {
      positives.add("No allergens detected");
    }
    if (getAdditives().isEmpty) {
      positives.add("No additives detected");
    }
    return positives.isNotEmpty ? positives : ["No notable positive aspects"];
  }

  List<String> getNegativeAspects() {
    List<String> negatives = [];
    if (getSugar() > 10) {
      negatives.add("High sugar content (${getSugar()}g per 100g)");
    }
    if (getFat() > 20) {
      negatives.add("High fat content (${getFat()}g per 100g)");
    }
    if (getSalt() > 2) {
      negatives.add("High salt content (${getSalt()}g per 100g)");
    }
    if (getEnergy() > 500) {
      negatives.add("High energy content (${getEnergy()} kcal per 100g)");
    }
    if (getFiber() < 1) {
      negatives.add("Low fiber content (${getFiber()}g per 100g)");
    }
    if (nutriScore != null && ['d', 'e'].contains(nutriScore!.toLowerCase())) {
      negatives.add("Poor Nutri-Score (${nutriScore!.toUpperCase()})");
    }
    if (novaGroup != null && novaGroup == '4') {
      negatives.add("Highly processed (NOVA Group 4)");
    }
    if (ecoScore != null && ['d', 'e'].contains(ecoScore!.toLowerCase())) {
      negatives.add(
        "Poor environmental impact (Eco-Score ${ecoScore!.toUpperCase()})",
      );
    }
    if (allergens != null && (allergens?.isNotEmpty ?? false)) {
      negatives.add("Contains allergens: $allergens");
    }
    final additivesList = getAdditives();
    if (additivesList.isNotEmpty) {
      negatives.add("Contains additives: ${additivesList.join(', ')}");
    }
    final ingredientAnalysis = analyzeIngredients();
    if (ingredientAnalysis['has_gluten'] == 1) {
      negatives.add("Contains gluten");
    }
    if (ingredientAnalysis['has_soy'] == 1) {
      negatives.add("Contains soy");
    }
    if (ingredientAnalysis['has_preservatives'] == 1) {
      negatives.add("Contains preservatives");
    }
    return negatives.isNotEmpty ? negatives : ["No notable negative aspects"];
  }

  List<String> getRecommendations() {
    List<String> recommendations = [];
    if (getSugar() > 10) {
      recommendations.add("Consume in moderation due to high sugar content.");
    }
    if (getFat() > 20) {
      recommendations.add("Consume in moderation due to high fat content.");
    }
    if (getSalt() > 2) {
      recommendations.add("Consume in moderation due to high salt content.");
    }
    if (getFiber() < 1) {
      recommendations.add(
        "Consider products with higher fiber content for better nutrition.",
      );
    }
    if (allergens != null && (allergens?.isNotEmpty ?? false)) {
      recommendations.add(
        "Avoid if you are allergic to any of the listed allergens ($allergens).",
      );
    }
    if (novaGroup != null && novaGroup == '4') {
      recommendations.add(
        "Consider choosing less processed alternatives (lower NOVA Group).",
      );
    }
    if (ecoScore != null && ['d', 'e'].contains(ecoScore!.toLowerCase())) {
      recommendations.add(
        "Look for more eco-friendly alternatives with a better Eco-Score.",
      );
    }
    if (getProtein() > 10) {
      recommendations.add("Good choice for a high-protein diet.");
    }
    final additivesList = getAdditives();
    if (additivesList.isNotEmpty) {
      recommendations.add(
        "Consider products with fewer or no additives for a healthier choice.",
      );
    }
    final ingredientAnalysis = analyzeIngredients();
    if (ingredientAnalysis['has_gluten'] == 1) {
      recommendations.add(
        "Avoid if you have gluten intolerance or celiac disease.",
      );
    }
    if (ingredientAnalysis['has_soy'] == 1) {
      recommendations.add("Avoid if you are allergic to soy.");
    }
    if (ingredientAnalysis['has_preservatives'] == 1) {
      recommendations.add(
        "Consider products without preservatives for a more natural diet.",
      );
    }
    return recommendations.isNotEmpty
        ? recommendations
        : ["No specific recommendations"];
  }
}
