import '../../domain/entities/branding_entity.dart';

class BrandingModel extends BrandingEntity {
  const BrandingModel({
    super.logoUrl,
    super.primaryColor,
    super.onPrimaryColor,
    super.slogan,
    super.contactEmail,
    super.contactPhone,
    super.contactAddress,
  });

  factory BrandingModel.fromJson(Map<String, dynamic> json) {
    return BrandingModel(
      logoUrl: json['logo_url']?.toString(),
      primaryColor: json['primary_color']?.toString(),
      onPrimaryColor: json['on_primary_color']?.toString(),
      slogan: json['slogan']?.toString(),
      contactEmail: json['contact_email']?.toString(),
      contactPhone: json['contact_phone']?.toString(),
      contactAddress: json['contact_address']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'logo_url': logoUrl,
      'primary_color': primaryColor,
      'on_primary_color': onPrimaryColor,
      'slogan': slogan,
      'contact_email': contactEmail,
      'contact_phone': contactPhone,
      'contact_address': contactAddress,
    }..removeWhere((_, value) => value == null);
  }

  BrandingModel merge(BrandingEntity other) {
    return BrandingModel(
      logoUrl: other.logoUrl ?? logoUrl,
      primaryColor: other.primaryColor ?? primaryColor,
      onPrimaryColor: other.onPrimaryColor ?? onPrimaryColor,
      slogan: other.slogan ?? slogan,
      contactEmail: other.contactEmail ?? contactEmail,
      contactPhone: other.contactPhone ?? contactPhone,
      contactAddress: other.contactAddress ?? contactAddress,
    );
  }
}