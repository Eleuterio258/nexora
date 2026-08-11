
class BrandingEntity {
  const BrandingEntity({
    this.logoUrl,
    this.primaryColor,
    this.onPrimaryColor,
    this.slogan,
    this.contactEmail,
    this.contactPhone,
    this.contactAddress,
  });

  final String? logoUrl;
  final String? primaryColor;
  final String? onPrimaryColor;
  final String? slogan;
  final String? contactEmail;
  final String? contactPhone;
  final String? contactAddress;

  bool get hasPrimaryColor =>
      primaryColor != null && primaryColor!.isNotEmpty;

  BrandingEntity copyWith({
    String? logoUrl,
    String? primaryColor,
    String? onPrimaryColor,
    String? slogan,
    String? contactEmail,
    String? contactPhone,
    String? contactAddress,
  }) {
    return BrandingEntity(
      logoUrl: logoUrl ?? this.logoUrl,
      primaryColor: primaryColor ?? this.primaryColor,
      onPrimaryColor: onPrimaryColor ?? this.onPrimaryColor,
      slogan: slogan ?? this.slogan,
      contactEmail: contactEmail ?? this.contactEmail,
      contactPhone: contactPhone ?? this.contactPhone,
      contactAddress: contactAddress ?? this.contactAddress,
    );
  }
}