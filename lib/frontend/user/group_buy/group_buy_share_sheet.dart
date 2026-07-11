import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../backend/models/group_buy.dart';
import '../../../backend/models/product.dart';
import '../../../backend/utils/group_buy_utils.dart';

enum GroupBuyInviteMode {
  created,
  joined,
}

Future<void> showGroupBuyInviteSheet({
  required BuildContext context,
  required GroupBuy deal,
  required Product product,
  GroupBuyInviteMode mode = GroupBuyInviteMode.joined,
}) {
  final shareUrl = GroupBuyUtils.buildShareUrl(deal);
  final shareMessage = GroupBuyUtils.buildAutoShareMessage(
    deal: deal,
    product: product,
  );

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mode == GroupBuyInviteMode.created
                    ? 'Tạo nhóm thành công!'
                    : 'Bạn đã tham gia nhóm thành công!',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                mode == GroupBuyInviteMode.created
                    ? 'Bạn là thành viên đầu tiên. Hãy mời thêm '
                        '${deal.membersStillNeeded} người để nhận giá ưu đãi.'
                    : 'Nhóm hiện có ${deal.currentBuyerCount}/${deal.maximumMember} người. '
                        'Hãy chia sẻ để nhóm nhanh đạt đủ số lượng.',
                style: const TextStyle(color: Color(0xFF667085)),
              ),
              const SizedBox(height: 16),
              const Text(
                'Mời bạn bè tham gia nhóm',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE4E7EC)),
                ),
                child: Text(
                  shareMessage,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                shareUrl,
                style: const TextStyle(
                  color: Color(0xFF1570EF),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE4E7EC)),
                  ),
                  child: QrImageView(
                    data: shareUrl,
                    version: QrVersions.auto,
                    size: 148,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _copyToClipboard(context, shareUrl),
                  icon: const Icon(Icons.link),
                  label: const Text('Sao chép liên kết'),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _SocialShareButton(
                      label: 'Zalo',
                      color: const Color(0xFF0068FF),
                      onTap: () => _shareExternal(
                        'https://zalo.me/share?url=${Uri.encodeComponent(shareUrl)}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SocialShareButton(
                      label: 'Messenger',
                      color: const Color(0xFF0084FF),
                      onTap: () => _shareExternal(
                        'https://www.facebook.com/dialog/send?link=${Uri.encodeComponent(shareUrl)}&app_id=87741124305&redirect_uri=${Uri.encodeComponent(shareUrl)}',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SocialShareButton(
                      label: 'Facebook',
                      color: const Color(0xFF1877F2),
                      onTap: () => _shareExternal(
                        'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent(shareUrl)}',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _copyToClipboard(context, shareMessage),
                  icon: const Icon(Icons.message_outlined),
                  label: const Text('Sao chép nội dung chia sẻ'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _copyToClipboard(BuildContext context, String value) async {
  await Clipboard.setData(ClipboardData(text: value));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã sao chép')),
    );
  }
}

Future<void> _shareExternal(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

class _SocialShareButton extends StatelessWidget {
  const _SocialShareButton({
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.35)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}
