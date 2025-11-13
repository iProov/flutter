import 'dart:convert';
import 'dart:ffi';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' hide Color;
import 'package:iproov_flutter/enums.dart';

/// Set options for the iProov SDK.
///
/// Most of these options are common to both Android and iOS, however, some are platform-specific.
///
/// All options are nullable and any options not set will default to their platform-defined default value.
@immutable
class Options {
  /// The [Filter] applied to the camera preview as either [LineDrawingFilter] or [NaturalFilter].
  final Filter? filter;

  /// The [Color] of the text in the title.
  final Color? titleTextColor;

  /// The [Color] to be applied to the [closeButtonImage].
  final Color? closeButtonTintColor;

  /// A custom [Image] to be used for the close button which appears in the header bar at the top of the screen
  /// on the left hand side.
  ///
  /// Note that only the alpha channel of the image is used, you can change the color of the button
  /// using [closeButtonTintColor].
  final Image? closeButtonImage;

  /// A custom title to appear in the header bar at the top of the screen.
  final String? title;

  /// Path to the font to use for the iProov UI. The font must be added to your app (TTF or OTF formats are supported).
  ///
  /// The font filename must match the name of the font.
  final String? fontPath;

  /// A small logo [Image] to display in the header bar at the top of the screen on the right hand side.
  final Image? logoImage;

  /// The [Color] of text in prompt box.
  final Color? promptTextColor;

  /// The [Color] to use for the background of the prompt.
  final Color? promptBackgroundColor;

  /// Whether the prompt should have rounded corners.
  final bool? promptRoundedCorners;

  /// Color applied to the area outside the oval.
  final Color? surroundColor;

  /// A [List] of [String]s containing the base64-encoded SHA-256 hash of each certificate's Subject Public Key Info.
  ///
  /// Certificate pinning can be disabled by passing an empty array (never do this in production apps!)
  final List<String>? certificates;

  /// The network timeout for establishing a network connection.
  final Duration? timeout;

  /// Whether screenshots should be allowed during the iProov scan process.
  ///
  /// This option only applies to Android.
  final bool? enableScreenshots;

  /// Sets the orientation of the iProov UI.
  ///
  /// This option only applies to Android.
  final Orientation? orientation;

  /// The [Color] of the header bar.
  final Color? headerBackgroundColor;

  /// Whether the blur and vignette effect outside the oval should be disabled.
  final bool? disableExteriorEffects;

  /// Options relating specifically to Genuine Presence Assurance (GPA).
  final GenuinePresenceAssuranceOptions? genuinePresenceAssurance;

  /// Options relating specifically to Liveness Assurance (LA).
  final LivenessAssuranceOptions? livenessAssurance;

  const Options({
    this.filter,
    this.titleTextColor,
    this.promptTextColor,
    this.closeButtonTintColor,
    this.closeButtonImage,
    this.title,
    this.fontPath,
    this.logoImage,
    this.promptBackgroundColor,
    this.promptRoundedCorners,
    this.surroundColor,
    this.certificates,
    this.timeout,
    this.enableScreenshots,
    this.orientation,
    this.headerBackgroundColor,
    this.disableExteriorEffects,
    this.genuinePresenceAssurance,
    this.livenessAssurance,
  });

  Map<String, dynamic> toJson() => {
        'filter': filter?.toJson(),
        'title_text_color': titleTextColor?.hex,
        'prompt_text_color': promptTextColor?.hex,
        'close_button_tint_color': closeButtonTintColor?.hex,
        if (closeButtonImage != null) 'close_button_image': base64.encode(encodePng(closeButtonImage!)),
        'title': title,
        'font': fontPath,
        if (logoImage != null) 'logo_image': base64.encode(encodePng(logoImage!)),
        'prompt_background_color': promptBackgroundColor?.hex,
        'prompt_rounded_corners': promptRoundedCorners,
        'surround_color': surroundColor?.hex,
        'certificates': certificates,
        'timeout': timeout?.inSeconds,
        'enable_screenshots': enableScreenshots,
        'orientation': orientation?.stringValue,
        'header_background_color': headerBackgroundColor?.hex,
        'disable_exterior_effects': disableExteriorEffects,
        'genuine_presence_assurance': genuinePresenceAssurance?.toJson(),
        'liveness_assurance': livenessAssurance?.toJson(),
      }._withoutNullValues();

  Options copyWith({
    Filter? filter,
    Color? titleTextColor,
    Color? promptTextColor,
    Color? closeButtonTintColor,
    Image? closeButtonImage,
    String? title,
    String? fontPath,
    Image? logoImage,
    Color? promptBackgroundColor,
    bool? promptRoundedCorners,
    Color? surroundColor,
    List<String>? certificates,
    Duration? timeout,
    bool? enableScreenshots,
    Orientation? orientation,
    Color? headerBackgroundColor,
    bool? disableExteriorEffects,
    GenuinePresenceAssuranceOptions? genuinePresenceAssurance,
    LivenessAssuranceOptions? livenessAssurance,
  }) =>
      Options(
        filter: filter ?? this.filter,
        titleTextColor: titleTextColor ?? this.titleTextColor,
        promptTextColor: promptTextColor ?? this.promptTextColor,
        closeButtonTintColor: closeButtonTintColor ?? this.closeButtonTintColor,
        closeButtonImage: closeButtonImage ?? this.closeButtonImage,
        title: title ?? this.title,
        fontPath: fontPath ?? this.fontPath,
        logoImage: logoImage ?? this.logoImage,
        promptBackgroundColor: promptBackgroundColor ?? this.promptBackgroundColor,
        promptRoundedCorners: promptRoundedCorners ?? this.promptRoundedCorners,
        surroundColor: surroundColor ?? this.surroundColor,
        certificates: certificates ?? this.certificates,
        timeout: timeout ?? this.timeout,
        enableScreenshots: enableScreenshots ?? this.enableScreenshots,
        orientation: orientation ?? this.orientation,
        headerBackgroundColor: headerBackgroundColor ?? this.headerBackgroundColor,
        disableExteriorEffects: disableExteriorEffects ?? this.disableExteriorEffects,
        genuinePresenceAssurance: genuinePresenceAssurance ?? this.genuinePresenceAssurance,
        livenessAssurance: livenessAssurance ?? this.livenessAssurance,
      );
}

/// Options relating to the appearance of the iProov user interface for GPA claims.
@immutable
class GenuinePresenceAssuranceOptions {
  /// The [Color] to use for the oval stroke line when the scan is ready to start.
  final Color? readyOvalStrokeColor;

  /// The [Color] to use for the oval stroke line when the scan is not ready to start.
  final Color? notReadyOvalStrokeColor;

  /// Whether to control y position of the face showing prompts.
  final bool? controlYPosition ;

  /// Whether to control x position of the face showing prompts.
  final bool? controlXPosition;

  /// Show a prompt 'Scanning' during GPA scan and show a prompt 'Scan Completed' after GPA scan completes.
  final bool? scanningPrompts;

  const GenuinePresenceAssuranceOptions({
    this.readyOvalStrokeColor,
    this.notReadyOvalStrokeColor,
    this.controlYPosition,
    this.controlXPosition,
    this.scanningPrompts,
  });

  Map<String, dynamic> toJson() => {
        'ready_oval_stroke_color': readyOvalStrokeColor?.hex,
        'not_ready_oval_stroke_color': notReadyOvalStrokeColor?.hex,
        'control_y_position': controlYPosition,
        'control_x_position': controlXPosition,
        'scanning_prompts': scanningPrompts,
      }._withoutNullValues();
}

/// Options relating to the appearance of the iProov user interface for LA claims.
@immutable
class LivenessAssuranceOptions {
  /// The [Color] to use for the oval stroke.
  final Color? ovalStrokeColor;

  /// The [Color] to use for the oval stroke after LA scan completes.
  final Color? completedOvalStrokeColor;

  const LivenessAssuranceOptions({
    this.ovalStrokeColor,
    this.completedOvalStrokeColor,
  });

  Map<String, dynamic> toJson() => {
        'oval_stroke_color': ovalStrokeColor?.hex,
        'completed_oval_stroke_color': completedOvalStrokeColor?.hex,
      }._withoutNullValues();
}

@immutable
abstract class Filter {
  Map<String, dynamic> toJson();
}

enum LineDrawingFilterStyle { classic, shaded, vibrant }

/// Options relating to the camera preview based on iProov's traditional "canny" filter
@immutable
class LineDrawingFilter implements Filter {
  /// The style to use for the filter. defaults to `.shaded`.
  final LineDrawingFilterStyle? style;

  /// The [Color] to use for the foreground of the filter.
  final Color? foregroundColor;

  /// The [Color] to use for the background of the filter.
  final Color? backgroundColor;

  const LineDrawingFilter({
    this.style,
    this.foregroundColor,
    this.backgroundColor,
  });

  @override
  Map<String, dynamic> toJson() => {
        'name': 'line_drawing',
        'style': style?.name,
        'foreground_color': foregroundColor?.hex,
        'background_color': backgroundColor?.hex,
      }._withoutNullValues();
}

enum NaturalFilterStyle { clear, blur }

/// Options relating to the camera preview providing direct visualization of the user's face.
/// Note that [NaturalFilter] is available for Liveness Assurance claims only.
/// Attempts to use [NaturalFilter] for Genuine Presence Assurance claims will result in an error.
@immutable
class NaturalFilter implements Filter {
  /// The style to use for the filter. defaults to `.clear`.
  final NaturalFilterStyle? style;

  const NaturalFilter({this.style});

  @override
  Map<String, dynamic> toJson() => {
        'name': 'natural',
        'style': style?.name,
      }._withoutNullValues();
}

extension on Color {
  String get hex => '#' + value.toRadixString(16);
}

extension on Map<String, dynamic> {
  Map<String, dynamic> _withoutNullValues() => Map.fromEntries(entries.where((e) => e.value != null));
}
