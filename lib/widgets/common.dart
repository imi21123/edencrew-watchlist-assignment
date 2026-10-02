import 'package:flutter/material.dart';

import '../models/stock.dart';
import '../theme/theme.dart';

Color movementColor(BuildContext context, double? change) =>
    change == null || change == 0
    ? context.colors.priceFlatText
    : change > 0
    ? context.colors.priceUpText
    : context.colors.priceDownText;

/// 데스크톱에서도 393×852 모바일 시안의 콘텐츠 위치를 유지한다.
/// 가짜 상태 바를 그리지 않고 OS 영역에 해당하는 여백만 확보한다.
class ScreenSafeArea extends StatelessWidget {
  const ScreenSafeArea({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => SafeArea(
    minimum: const EdgeInsets.only(top: 59, bottom: 34),
    child: child,
  );
}

class StockIdentity extends StatelessWidget {
  const StockIdentity({super.key, required this.stock, this.query = ''});
  final Stock stock;
  final String query;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text.rich(
        TextSpan(
          children: highlightedName(
            stock.name,
            query,
            context.colors.searchHighlight,
          ),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: context.colors.textPrimary,
          fontSize: 14,
          fontWeight: AppTypography.medium,
        ),
      ),
      SizedBox(height: context.dimens.space1),
      Text(
        '${stock.symbol} · ${stock.market}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: context.colors.textTertiary, fontSize: 10),
      ),
    ],
  );
}

List<TextSpan> highlightedName(String name, String query, Color highlight) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return [TextSpan(text: name)];
  final lower = name.toLowerCase();
  final spans = <TextSpan>[];
  var offset = 0;
  while (offset < name.length) {
    final index = lower.indexOf(needle, offset);
    if (index < 0) {
      spans.add(TextSpan(text: name.substring(offset)));
      break;
    }
    if (index > offset) {
      spans.add(TextSpan(text: name.substring(offset, index)));
    }
    spans.add(
      TextSpan(
        text: name.substring(index, index + needle.length),
        style: TextStyle(color: highlight),
      ),
    );
    offset = index + needle.length;
  }
  return spans;
}

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({
    super.key,
    required this.active,
    required this.onPressed,
  });
  final bool active;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: active ? '관심 해제' : '관심 등록',
    onPressed: onPressed,
    icon: Icon(
      active ? Icons.star_rounded : Icons.star_border_rounded,
      size: context.dimens.iconMd,
      color: active
          ? context.colors.favoriteActive
          : context.colors.favoriteInactive,
    ),
  );
}

void showFavoriteToast(
  BuildContext context,
  bool added, {
  bool aboveTabs = true,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.removeCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      backgroundColor: context.colors.surfaceOverlay,
      elevation: 0,
      margin: EdgeInsets.fromLTRB(
        context.dimens.space4,
        0,
        context.dimens.space4,
        context.dimens.space4 +
            34 +
            (aboveTabs ? context.dimens.tabBarHeight : 0),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: context.dimens.space4,
        vertical: context.dimens.space3,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.dimens.radiusMd),
      ),
      content: Row(
        children: [
          Icon(
            added ? Icons.star_rounded : Icons.star_border_rounded,
            size: context.dimens.iconSm,
            color: added
                ? context.colors.favoriteActive
                : context.colors.textSecondary,
          ),
          SizedBox(width: context.dimens.space2),
          Expanded(
            child: Text(
              added ? '관심이 등록되었습니다' : '관심이 해제되었습니다',
              style: TextStyle(color: context.colors.textPrimary, fontSize: 12),
            ),
          ),
        ],
      ),
    ),
  );
}

class EmptyMessage extends StatelessWidget {
  const EmptyMessage({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
  });
  final IconData icon;
  final String title, description;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: EdgeInsets.all(context.dimens.space6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: context.dimens.iconMd + context.dimens.space3,
            color: context.colors.textTertiary,
          ),
          SizedBox(height: context.dimens.space4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: AppTypography.bold,
              color: context.colors.textSecondary,
            ),
          ),
          SizedBox(height: context.dimens.space2),
          Text(
            description,
            textAlign: TextAlign.center,
            softWrap: true,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: context.colors.textTertiary,
            ),
          ),
        ],
      ),
    ),
  );
}

class ErrorNotice extends StatelessWidget {
  const ErrorNotice({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(
      horizontal: context.dimens.space4,
      vertical: context.dimens.space2,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: context.colors.feedbackWarning, fontSize: 12),
        ),
        TextButton(onPressed: onRetry, child: const Text('다시 시도')),
      ],
    ),
  );
}

class Skeleton extends StatelessWidget {
  const Skeleton({super.key, required this.width, this.height = 12});
  final double width, height;
  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: context.colors.feedbackSkeleton,
      borderRadius: BorderRadius.circular(context.dimens.radiusSm),
    ),
  );
}

class LoadingRows extends StatelessWidget {
  const LoadingRows({super.key});
  @override
  Widget build(BuildContext context) => ListView.builder(
    itemCount: 4,
    itemBuilder: (context, index) => Padding(
      padding: EdgeInsets.all(context.dimens.space4),
      child: Row(
        children: [
          const Expanded(child: Skeleton(width: 120)),
          SizedBox(width: context.dimens.space6),
          const Skeleton(width: 32),
        ],
      ),
    ),
  );
}
