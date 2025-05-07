import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:camerawesome/pigeon.dart';
import 'package:camerawesome/src/orchestrator/camera_context.dart';
import 'package:flutter/foundation.dart';

typedef OnVideoMode = Function(VideoCameraState);

typedef OnPhotoMode = Function(PhotoCameraState);

typedef OnPreparingCamera = Function(PreparingCameraState);

typedef OnVideoRecordingMode = Function(VideoRecordingCameraState);

typedef OnPreviewMode = Function(PreviewCameraState);

typedef OnAnalysisOnlyMode = Function(AnalysisCameraState);

abstract class CameraState {
  // TODO Make private
  @protected
  CameraContext cameraContext;

  CameraState(this.cameraContext);

  abstract final CaptureMode? captureMode;

  when({
    OnVideoMode? onVideoMode,
    OnPhotoMode? onPhotoMode,
    OnPreparingCamera? onPreparingCamera,
    OnVideoRecordingMode? onVideoRecordingMode,
    OnPreviewMode? onPreviewMode,
    OnAnalysisOnlyMode? onAnalysisOnlyMode,
  }) {
    return switch (this) {
      (VideoCameraState state) => onVideoMode?.call(state),
      (PhotoCameraState state) => onPhotoMode?.call(state),
      (PreparingCameraState state) => onPreparingCamera?.call(state),
      (VideoRecordingCameraState state) => onVideoRecordingMode?.call(state),
      (PreviewCameraState state) => onPreviewMode?.call(state),
      (AnalysisCameraState state) => onAnalysisOnlyMode?.call(state),
      CameraState() => null,
    };
  }

  /// Closes streams depending on the current state
  void dispose();

  /// Use this stream to listen for capture state
  /// - while recording a video
  /// - while saving an image
  /// Accessible from all states
  Stream<MediaCapture?> get captureState$ => cameraContext.captureState$;

  MediaCapture? get captureState => cameraContext.captureState;

  /// Switch camera from [Sensors.BACK] [Sensors.front]
  /// All states can switch this
  Future<void> switchCameraSensor({
    CameraAspectRatios? aspectRatio,
    double? zoom,
    FlashMode? flash,
    SensorType? type,
  }) async {
    try {
      // Get current configuration
      final previous = cameraContext.sensorConfig;
      SensorConfig next;

      // Create new configuration
      if (previous.sensors.length <= 1) {
        next = SensorConfig.single(
          sensor: previous.sensors.first.position == SensorPosition.back
              ? Sensor.position(SensorPosition.front)
              : Sensor.position(SensorPosition.back),
          aspectRatio: aspectRatio ?? previous.aspectRatio,
          zoom: zoom ?? previous.zoom,
          flashMode: flash ?? previous.flashMode,
        );
      } else {
        final newSensorsCopy = [...previous.sensors.nonNulls];
        next = SensorConfig.multiple(
          sensors: newSensorsCopy
            ..insert(0, newSensorsCopy.removeAt(newSensorsCopy.length - 1)),
          aspectRatio: aspectRatio ?? previous.aspectRatio,
          zoom: zoom ?? previous.zoom,
          flashMode: flash ?? previous.flashMode,
        );
      }

      // First step: Stop the camera completely
      // await cameraContext.stopCamera();

      // Wait to ensure camera is fully stopped
      await Future.delayed(Duration(milliseconds: 300));

      // Set new sensor configuration
      await cameraContext.setSensorConfig(next);

      // Wait to ensure configuration is applied
      await Future.delayed(Duration(milliseconds: 200));

      // Start camera with new configuration
      // await cameraContext.startCamera();

      // Apply specific settings after camera is started if needed
      if (aspectRatio != null && aspectRatio != previous.aspectRatio) {
        await next.setAspectRatio(aspectRatio);
      }

      if (zoom != null && zoom != previous.zoom) {
        await next.setZoom(zoom);
      }

      if (flash != null && flash != previous.flashMode) {
        await next.setFlashMode(flash);
      }
    } catch (e, stackTrace) {
      // Recovery attempt
      try {
        // await cameraContext.startCamera();
      } catch (recoveryError) {
        // Last resort - try to reinitialize the entire camera
        try {
          await cameraContext.dispose();
          await Future.delayed(Duration(milliseconds: 500));
          // await cameraContext.initialize();
        } catch (reinitError) {}
      }
    }
  }

  void setSensorType(int cameraPosition, SensorType type, String deviceId) {
    final previous = cameraContext.sensorConfig;
    int sensorIndex = 0;
    final next = SensorConfig.multiple(
      sensors: previous.sensors
          .map((sensor) {
            if (sensorIndex == cameraPosition) {
              if (sensor.type == SensorType.trueDepth) {
                sensor.position = SensorPosition.front;
              } else {
                sensor.position = SensorPosition.back;
              }

              sensor.deviceId = deviceId;
              sensor.type = type;
            }

            sensorIndex++;
            return sensor;
          })
          .nonNulls
          .toList(),
      aspectRatio: previous.aspectRatio,
      flashMode: previous.flashMode,
      zoom: previous.zoom,
    );
    cameraContext.setSensorConfig(next);
  }

  // PigeonSensorType? _sensorTypeFromPigeon(SensorType type) {
  //   switch (type) {
  //     case SensorType.wideAngle:
  //       return PigeonSensorType.wideAngle;
  //     case SensorType.telephoto:
  //       return PigeonSensorType.telephoto;
  //     case SensorType.trueDepth:
  //       return PigeonSensorType.trueDepth;
  //     case SensorType.ultraWideAngle:
  //       return PigeonSensorType.ultraWideAngle;
  //     default:
  //       return null;
  //   }
  // }

  void toggleFilterSelector() {
    cameraContext.toggleFilterSelector();
  }

  Future<void> setFilter(AwesomeFilter newFilter) {
    return cameraContext.setFilter(newFilter);
  }

  /// The sensor config allows you to
  /// - set the [FlashMode]
  /// - set the zoom level
  /// - handle luminosity or get it
  /// - adjust brightness
  SensorConfig get sensorConfig => cameraContext.sensorConfig;

  Stream<SensorConfig> get sensorConfig$ => cameraContext.sensorConfig$;

  Stream<bool> get filterSelectorOpened$ => cameraContext.filterSelectorOpened$;

  Stream<AwesomeFilter> get filter$ => cameraContext.filter$;

  AwesomeFilter get filter => cameraContext.filterController.value;

  /// Switch to a state between
  /// - [CaptureMode.photo]
  /// - [CaptureMode.video]
  /// - [CaptureMode.ANALYSIS]
  void setState(CaptureMode captureMode);

  SaveConfig? get saveConfig => cameraContext.saveConfig;

  Future<PreviewSize> previewSize(int index) {
    return cameraContext.previewSize(index);
  }

  Future<SensorDeviceData> getSensors() {
    return cameraContext.getSensors();
  }

  Future<int?> previewTextureId(int cameraPosition) {
    return cameraContext.previewTextureId(cameraPosition);
  }

  AnalysisController? get analysisController =>
      cameraContext.analysisController;
}
