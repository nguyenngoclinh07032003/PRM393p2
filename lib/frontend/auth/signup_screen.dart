import 'package:flutter/material.dart';
import 'package:prm393_pharmacy/app_routes.dart';
import 'package:provider/provider.dart';
import '../../backend/services/auth_service.dart';
import '../../backend/services/error_handler.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  void _togglePasswordVisibility() {
    setState(() => _obscurePassword = !_obscurePassword);
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
      );

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.home, (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ErrorHandler.getErrorMessage(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthShell(form: _SignupFormHost());
  }
}

class _SignupFormHost extends StatelessWidget {
  const _SignupFormHost();

  @override
  Widget build(BuildContext context) {
    final state = context.findAncestorStateOfType<_SignupScreenState>()!;

    return Form(
      key: state._formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Tạo tài khoản mới',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF151515),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Đăng ký để săn ưu đãi, flash sale và quản lý lịch sử mua hàng dễ dàng.',
            style: TextStyle(
              height: 1.45,
              fontSize: 14,
              color: Color(0xFF6E6E6E),
            ),
          ),
          const SizedBox(height: 28),
          const Row(
            children: [
              Expanded(child: _SocialButton(icon: Icons.g_mobiledata, label: 'Google')),
              SizedBox(width: 14),
              Expanded(child: _SocialButton(icon: Icons.facebook, label: 'Facebook')),
            ],
          ),
          const SizedBox(height: 24),
          const _DividerLabel(label: 'HOẶC ĐĂNG KÝ BẰNG EMAIL'),
          const SizedBox(height: 24),
          const _FieldLabel('Họ và tên'),
          const SizedBox(height: 8),
          TextFormField(
            controller: state._nameController,
            decoration: _AuthDecorations.input(
              hintText: 'Nguyễn Văn A',
              icon: Icons.person_outline,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập họ tên';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          const _FieldLabel('Email'),
          const SizedBox(height: 8),
          TextFormField(
            controller: state._emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: _AuthDecorations.input(
              hintText: 'name@example.com',
              icon: Icons.mail_outline,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập email';
              }
              if (!value.contains('@')) {
                return 'Email không hợp lệ';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          const _FieldLabel('Số điện thoại'),
          const SizedBox(height: 8),
          TextFormField(
            controller: state._phoneController,
            keyboardType: TextInputType.phone,
            decoration: _AuthDecorations.input(
              hintText: '0901234567',
              icon: Icons.phone_outlined,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập số điện thoại';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          const _FieldLabel('Địa chỉ giao hàng'),
          const SizedBox(height: 8),
          TextFormField(
            controller: state._addressController,
            maxLines: 2,
            decoration: _AuthDecorations.input(
              hintText: 'Số nhà, đường, quận/huyện, thành phố',
              icon: Icons.location_on_outlined,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập địa chỉ giao hàng';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          const _FieldLabel('Mật khẩu'),
          const SizedBox(height: 8),
          TextFormField(
            controller: state._passwordController,
            obscureText: state._obscurePassword,
            decoration: _AuthDecorations.input(
              hintText: '••••••••',
              icon: Icons.lock_outline,
              suffix: IconButton(
                icon: Icon(
                  state._obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 18,
                ),
                onPressed: () {
                  state._togglePasswordVisibility();
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập mật khẩu';
              }
              if (value.length < 6) {
                return 'Mật khẩu phải có ít nhất 6 ký tự';
              }
              return null;
            },
          ),
          const SizedBox(height: 14),
          const _FieldLabel('Xác nhận mật khẩu'),
          const SizedBox(height: 8),
          TextFormField(
            controller: state._confirmPasswordController,
            obscureText: state._obscureConfirmPassword,
            decoration: _AuthDecorations.input(
              hintText: '••••••••',
              icon: Icons.lock_reset_outlined,
              suffix: IconButton(
                icon: Icon(
                  state._obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 18,
                ),
                onPressed: () {
                  state._toggleConfirmPasswordVisibility();
                },
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng xác nhận mật khẩu';
              }
              if (value != state._passwordController.text) {
                return 'Mật khẩu không khớp';
              }
              return null;
            },
          ),
          const SizedBox(height: 22),
          _PrimaryButton(
            label: 'Đăng ký',
            isLoading: state._isLoading,
            onPressed: state._handleSignup,
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Đã có tài khoản? ',
                style: TextStyle(color: Color(0xFF777777), fontSize: 13),
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false),
                child: const Text(
                  'Đăng nhập',
                  style: TextStyle(
                    color: _AuthDecorations.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AuthShell extends StatelessWidget {
  const _AuthShell({required this.form});

  final Widget form;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F6FA),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            return SingleChildScrollView(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  margin: EdgeInsets.all(isWide ? 24 : 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFCEC5FF), width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Expanded(
                              flex: 5,
                              child: SizedBox(
                                height: 620,
                                child: _PromoPanel(),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  32,
                                  24,
                                  32,
                                ),
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: 360,
                                    ),
                                    child: form,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              height: constraints.maxHeight < 700 ? 220 : 300,
                              child: const _PromoPanel(),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                              child: form,
                            ),
                          ],
                        ),
                      const _AuthFooter(),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PromoPanel extends StatelessWidget {
  const _PromoPanel();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.network(
          'https://images.unsplash.com/photo-1519567241046-7f570eee3ce6?auto=format&fit=crop&w=1200&q=80',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(color: const Color(0xFF2D2D2D)),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.08),
                Colors.black.withValues(alpha: 0.52),
                Colors.black.withValues(alpha: 0.82),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(54, 0, 54, 58),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  _LogoMark(size: 40),
                  SizedBox(width: 12),
                  Text(
                    'SmartDeal Shop',
                    style: TextStyle(
                      color: _AuthDecorations.accent,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text.rich(
                TextSpan(
                  text: 'Giải pháp mua sắm\n',
                  children: [
                    TextSpan(
                      text: 'thông minh & tiết kiệm',
                      style: TextStyle(color: _AuthDecorations.accent),
                    ),
                  ],
                ),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 38,
                  height: 1.15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Trải nghiệm nền tảng thương mại điện tử hàng đầu với hệ thống giá bậc thang linh hoạt. Mua càng nhiều, giá càng rẻ.',
                style: TextStyle(
                  color: Colors.white,
                  height: 1.55,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 44),
              const Wrap(
                spacing: 34,
                runSpacing: 16,
                children: [
                  _PromoBullet('Giá sỉ từ 1 sản phẩm'),
                  _PromoBullet('Flash Sale mỗi giờ'),
                  _PromoBullet('Giao hàng siêu tốc'),
                  _PromoBullet('Hỗ trợ 24/7'),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PromoBullet extends StatelessWidget {
  const _PromoBullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: _AuthDecorations.accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthFooter extends StatelessWidget {
  const _AuthFooter();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEDEDED))),
      ),
      padding: const EdgeInsets.fromLTRB(54, 26, 54, 22),
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 720;
              final children = [
                const _FooterBrand(),
                const _FooterColumn(title: 'QUICK LINKS', items: ['Browse Products', 'My History', 'Purchase Stats']),
                const _FooterColumn(title: 'SUPPORT', items: ['Help Center', 'Returns Policy', 'Flash Sale Terms', 'Admin Access']),
                const _FooterColumn(title: 'CONTACT', items: ['123 Commerce St, Tech City', 'support@smartdealshop.com']),
              ];

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children
                      .map((child) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 20), child: child)))
                      .toList(),
                );
              }

              return Wrap(
                spacing: 28,
                runSpacing: 24,
                children: children.map((child) => SizedBox(width: 240, child: child)).toList(),
              );
            },
          ),
          const SizedBox(height: 34),
          const Divider(color: Color(0xFFEDEDED)),
          const SizedBox(height: 16),
          const Text(
            '© 2026 SmartDeal Shop. All rights reserved.',
            style: TextStyle(color: Color(0xFF8A8A8A), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _FooterBrand extends StatelessWidget {
  const _FooterBrand();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _LogoMark(size: 30),
            SizedBox(width: 8),
            Text(
              'SmartDeal Shop',
              style: TextStyle(
                color: _AuthDecorations.accent,
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Text(
          'Your premier destination for bulk savings and flash deals. Smart shopping starts here.',
          style: TextStyle(color: Color(0xFF777777), fontSize: 12, height: 1.6),
        ),
      ],
    );
  }
}

class _FooterColumn extends StatelessWidget {
  const _FooterColumn({required this.title, required this.items});

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF202020),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 14),
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              item,
              style: const TextStyle(color: Color(0xFF777777), fontSize: 12),
            ),
          ),
      ],
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _AuthDecorations.accent,
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Icon(Icons.shopping_bag_outlined, color: Colors.white, size: size * 0.58),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 18, color: const Color(0xFF151515)),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF151515),
        side: const BorderSide(color: Color(0xFFE1E1E1)),
        padding: const EdgeInsets.symmetric(vertical: 14),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: Color(0xFFE1E1E1))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(color: Color(0xFF999999), fontSize: 10, fontWeight: FontWeight.w700),
          ),
        ),
        const Expanded(child: Divider(color: Color(0xFFE1E1E1))),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF2D2D2D)),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.isLoading, required this.onPressed});

  final String label;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: _AuthDecorations.accent,
        foregroundColor: Colors.white,
        disabledBackgroundColor: _AuthDecorations.accent.withValues(alpha: 0.45),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 17),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label),
                const SizedBox(width: 12),
                const Icon(Icons.arrow_forward, size: 16),
              ],
            ),
    );
  }
}

class _AuthDecorations {
  static const accent = Color(0xFF35C9E6);

  static InputDecoration input({
    required String hintText,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
      prefixIcon: Icon(icon, size: 19, color: const Color(0xFF777777)),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE1E1E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: accent, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }
}






