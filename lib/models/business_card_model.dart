class BusinessCardModel {
  final String name;
  final String jobTitle;
  final String company;
  final String phone;
  final String email;
  final String website;
  final String address;
  final int cardThemeIndex;
  final String imageUrl;

  BusinessCardModel({
    required this.name,
    required this.jobTitle,
    required this.company,
    required this.phone,
    required this.email,
    required this.website,
    required this.address,
    required this.cardThemeIndex,
    this.imageUrl = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'jobTitle': jobTitle,
      'company': company,
      'phone': phone,
      'email': email,
      'website': website,
      'address': address,
      'cardThemeIndex': cardThemeIndex,
      'imageUrl': imageUrl,
    };
  }

  factory BusinessCardModel.fromJson(Map<String, dynamic> json) {
    return BusinessCardModel(
      name: json['name'] ?? '',
      jobTitle: json['jobTitle'] ?? '',
      company: json['company'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      website: json['website'] ?? '',
      address: json['address'] ?? '',
      cardThemeIndex: json['cardThemeIndex'] ?? 0,
      imageUrl: json['imageUrl'] ?? '',
    );
  }

  factory BusinessCardModel.empty() {
    return BusinessCardModel(
      name: '',
      jobTitle: '',
      company: '',
      phone: '',
      email: '',
      website: '',
      address: '',
      cardThemeIndex: 0,
      imageUrl: '',
    );
  }

  // Generate standard vCard 3.0 format text
  String toVCardString() {
    return 'BEGIN:VCARD\r\n'
        'VERSION:3.0\r\n'
        'FN:$name\r\n'
        'ORG:$company\r\n'
        'TITLE:$jobTitle\r\n'
        'TEL;TYPE=CELL:$phone\r\n'
        'EMAIL;TYPE=PREF,INTERNET:$email\r\n'
        'URL:$website\r\n'
        'ADR;TYPE=WORK:;;$address\r\n'
        'END:VCARD';
  }
}
