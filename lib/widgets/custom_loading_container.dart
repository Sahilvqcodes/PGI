import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';


class CustomLoadingContainer extends StatelessWidget {
  final double? borderRadius;
  final Color? backgroundColor;
  final double? height;
  final Color? loadingColor;

  const CustomLoadingContainer({
    super.key,
    this.borderRadius,
    this.backgroundColor,
    this.height,
    this.loadingColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height ?? 55,
      decoration: BoxDecoration(
        color: Color(0xFF0D2C54) ,
        borderRadius: BorderRadius.circular(borderRadius ?? 50),
      ),
      child: Center(
        child: LoadingIndicator(
          indicatorType: Indicator.ballPulse,
          colors: [loadingColor ?? Colors.white],
          strokeWidth: 2,
          backgroundColor: Colors.transparent,
          pathBackgroundColor: Colors.black,
        ),
      ),
    );
  }
}
