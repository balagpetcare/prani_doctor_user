import 'package:flutter/material.dart';

import '../theme/home_tokens.dart';
import 'home_shimmer.dart';

class HomePageSkeleton extends StatelessWidget {
  const HomePageSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const CustomScrollView(
      physics: NeverScrollableScrollPhysics(),
      slivers: [
        SliverAppBar(
          pinned: true,
          title: HomeShimmerBox(
            width: 120,
            height: 24,
            borderRadius: HomeTokens.radiusSm,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(
              HomeTokens.space16,
              HomeTokens.space16,
              HomeTokens.space16,
              0,
            ),
            child: Column(
              children: [
                HomeShimmerBox(
                  height: 88,
                  borderRadius: HomeTokens.radiusLg,
                ),
                SizedBox(height: HomeTokens.space16),
                Row(
                  children: [
                    Expanded(
                      child: HomeShimmerBox(
                        height: 72,
                        borderRadius: HomeTokens.radiusMd,
                      ),
                    ),
                    SizedBox(width: HomeTokens.space12),
                    Expanded(
                      child: HomeShimmerBox(
                        height: 72,
                        borderRadius: HomeTokens.radiusMd,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: HomeTokens.space12),
                Row(
                  children: [
                    Expanded(
                      child: HomeShimmerBox(
                        height: 72,
                        borderRadius: HomeTokens.radiusMd,
                      ),
                    ),
                    SizedBox(width: HomeTokens.space12),
                    Expanded(
                      child: HomeShimmerBox(
                        height: 72,
                        borderRadius: HomeTokens.radiusMd,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: HomeTokens.space20),
                HomeShimmerBox(
                  height: 160,
                  borderRadius: HomeTokens.radiusLg,
                ),
                SizedBox(height: HomeTokens.space16),
                HomeShimmerBox(
                  height: 120,
                  borderRadius: HomeTokens.radiusLg,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
