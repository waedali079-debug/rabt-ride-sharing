import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:rabt/core/services/auth_service.dart';
import 'package:rabt/core/models/country.dart';
import 'otp_verification_screen.dart';

class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({Key? key}) : super(key: key);

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  Country _selectedCountry = Country.defaultCountry;

  String get _fullPhone => '${_selectedCountry.dialCode}${_phoneController.text.trim()}';

  Future<void> _sendOtp() async {
    final rawPhone = _phoneController.text.trim();
    if (rawPhone.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('الرجاء إدخال رقم هاتف صحيح')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _authService.sendOtp(_fullPhone);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(phoneNumber: _fullPhone),
          ),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ غير متوقع')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return CountryPickerSheet(
              scrollController: scrollController,
              onSelected: (country) {
                setState(() => _selectedCountry = country);
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل الدخول')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              Text(
                'أدخل رقم هاتفك',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'سنرسلك رمز تأكيد عبر رسالة نصية SMS',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 1),
              Row(
                children: [
                  GestureDetector(
                    onTap: _openCountryPicker,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_selectedCountry.flag, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 6),
                          Text(
                            _selectedCountry.dialCode,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        hintText: _selectedCountry.code == 'SA' ? '05XXXXXXXX' : 'رقم الهاتف',
                      ),
                      style: Theme.of(context).textTheme.titleLarge,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'مثال: ${_selectedCountry.dialCode} ${_selectedCountry.code == 'SA' ? '5XXXXXXXX' : 'XXXXXXXXXX'}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
              ElevatedButton(
                onPressed: _isLoading ? null : _sendOtp,
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('إرسال الرمز'),
              ),
              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }
}

class CountryPickerSheet extends StatefulWidget {
  final ScrollController scrollController;
  final Function(Country) onSelected;

  const CountryPickerSheet({
    Key? key,
    required this.scrollController,
    required this.onSelected,
  }) : super(key: key);

  @override
  State<CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<CountryPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<Country> _filtered = Country.countries;

  void _search(String query) {
    setState(() => _filtered = Country.search(query));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'اختر الدولة',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            onChanged: _search,
            decoration: InputDecoration(
              hintText: 'ابحث عن الدولة...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _search('');
                      },
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            controller: widget.scrollController,
            itemCount: _filtered.length,
            itemBuilder: (context, index) {
              final country = _filtered[index];
              return ListTile(
                leading: Text(country.flag, style: const TextStyle(fontSize: 24)),
                title: Text(country.name),
                trailing: Text(
                  country.dialCode,
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () => widget.onSelected(country),
              );
            },
          ),
        ),
      ],
    );
  }
}
