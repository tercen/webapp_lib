import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:webapp_components/abstract/component.dart';
import 'package:webapp_components/components/fetch_component.dart';
import 'package:webapp_components/definitions/component.dart';
import 'package:webapp_components/widgets/wait_indicator.dart';


class ImageUpdateComponent extends FetchComponent implements Component{
  double currentZoom = 1.5;
  Image? waitImg;
  ImageUpdateComponent(super.id, super.groupId, super.componentLabel, super.dataFetchFunc ){
    super.useCache = false;
  }

  @override
  Widget buildContent(BuildContext context) {
    return build(context);
  }
    @override
  Widget createWidget(BuildContext context) {
    final img =  Image.memory(
      Uint8List.fromList(dataTable["data"].first.codeUnits),
      fit: BoxFit.fitHeight,
      scale: currentZoom, 
    );

    waitImg =   Image.memory(
      Uint8List.fromList(dataTable["data"].first.codeUnits),
      fit: BoxFit.fitHeight,
      scale: currentZoom
    );
    return img;

  }

  void zoomIn(){
    if( currentZoom > 0.5 ){
      currentZoom = currentZoom - 0.25;
    }
  }

  void zoomOut(){
    if( currentZoom < 4 ){
      currentZoom = currentZoom + 0.25;
    }
  }

  @override
  ComponentType getComponentType() {
    return ComponentType.simpleNoLabel;
  }

  @override
  getComponentValue() {
    return "";
  }

  @override
  bool isFulfilled() {
    return true;
  }

  @override
  void setComponentValue(value) {
    
  }

  @override
  Widget build(BuildContext context) {
    if (isBusy) {
      return waitImg != null ?
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            TercenWaitIndicator()
              .waitingMessage(suffixMsg: "  Updating Image"),
            Opacity(opacity: 0.35,  child: waitImg!) ,
            
          ],) :
          TercenWaitIndicator()
              .waitingMessage(suffixMsg: "  Building Image");
    } else {
      if (dataTable.nRows == 0) {
        return buildEmptyTable();
      } else {
        return createWidget(context);
      }
    }
  }
}