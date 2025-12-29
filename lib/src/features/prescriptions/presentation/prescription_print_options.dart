class PrescriptionPrintOptions {
  final bool showLogo;
  final bool showNotes;
  final bool showAllergies;
  final bool showAdvice;
  final bool showQrCode;
  final bool showBranding;
  final bool showBorders;
  final bool showEmail;
  final String? backgroundImagePath;
  final double backgroundOpacity;

  const PrescriptionPrintOptions({
    this.showLogo = false, // Default false for clean look
    this.showNotes = false,
    this.showAllergies = false,
    this.showAdvice = false,
    this.showQrCode = false,
    this.showBranding = false, // Default false
    this.showBorders = false,
    this.showEmail = false,
    this.backgroundImagePath,
    this.backgroundOpacity = 0.2, // Default 20% opacity
  });

  PrescriptionPrintOptions copyWith({
    bool? showLogo,
    bool? showNotes,
    bool? showAllergies,
    bool? showAdvice,
    bool? showQrCode,
    bool? showBranding,
    bool? showBorders,
    bool? showEmail,
    String? backgroundImagePath,
    double? backgroundOpacity,
  }) {
    return PrescriptionPrintOptions(
      showLogo: showLogo ?? this.showLogo,
      showNotes: showNotes ?? this.showNotes,
      showAllergies: showAllergies ?? this.showAllergies,
      showAdvice: showAdvice ?? this.showAdvice,
      showQrCode: showQrCode ?? this.showQrCode,
      showBranding: showBranding ?? this.showBranding,
      showBorders: showBorders ?? this.showBorders,
      showEmail: showEmail ?? this.showEmail,
      backgroundImagePath: backgroundImagePath ?? this.backgroundImagePath,
      backgroundOpacity: backgroundOpacity ?? this.backgroundOpacity,
    );
  }
}
