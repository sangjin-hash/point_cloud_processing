## Introduction

A 3D human model generation application utilizing LiDAR sensor for real-time depth capture and reconstruction.

### - Demo
https://youtube.com/shorts/h4RJlyFW_bY

<table>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/cc35aed8-df94-4e27-bfa7-19318185eb10" width="300"/></td>
    <td><img src="https://github.com/user-attachments/assets/81cfbb1b-97e5-401c-896d-7e45df66f376" width="300"/></td>
  </tr>
  <tr>
    <td><img src="https://github.com/user-attachments/assets/4802b220-9f0e-4e37-bb4e-fe8d9fb8d5eb" width="300"/></td>
    <td><img src="https://github.com/user-attachments/assets/95909585-609c-49e4-b8c5-8aae5da5e28e" width="300"/></td>
  </tr>
</table>

<br></br>

## Features
### 1. 3D Scanning(Main Camera(rear-facing camera) with Lidar sensor & TrueDepth Camera)
- Real-time 3D Scan: Generate 3D point clouds in real-time using ARKit's Scene Depth
- TrueDepth Camera Support: Precise face and object scanning using front TrueDepth camera
- Segmentation Toggle: Enable/disable object segmentation during scanning
- RGB Texture Mapping: Option to include/exclude color information in point clouds

### 2. Gallery
- Scan Data Management: Organize and display all saved 3D scan files by date
- 3D Viewer: Built-in 3D viewer using SceneKit for immediate result viewing
- Measurement Data Viewer: Visualize saved measurement data

<br></br>

## Challenges
### 1. Human Segmentation for Point Cloud Collection
Applied person segmentation to capture only human-related depth data, filtering out background elements for cleaner 3D models.

### 2. Graphics API Shader for Coordinate Transformation
Implemented custom Metal shaders to transform point cloud data from local camera space to world coordinates, ensuring accurate spatial positioning of captured 3D data.

### 3. 3D Viewer Development
Built a custom 3D viewer using SceneKit to render and interact with captured point cloud data and reconstructed meshes.

<br></br>

## Frameworks & Libraries
- SwiftUI & UIKit: Hybrid UI implementation
- ARKit: 3D scanning and depth data collection
- Metal & MetalKit: GPU-accelerated high-performance rendering
- SceneKit: 3D model display and manipulation
- [StandardCyborgFusion](https://github.com/StandardCyborg/StandardCyborgCocoa): 3D reconstruction and mesh generation

<br></br>

## Getting Started
```bash
# Clone the repo
git clone https://github.com/sangjin-hash/point_cloud_processing.git
cd Creadto

# Install pods
pod install

# open the workspace
open Creadto.xcworkspace
```

<br></br>

## Project Structure
```
Creadto/
├── Creadto/
│   ├── CreadtoApp.swift          
│   ├── MainTabView.swift         
│   ├── Camera/                   # 3D scanning
│   │   ├── MainController.swift  # AR session and UI management
│   │   ├── Renderer.swift        # Metal rendering logic
        ├── Preview/              # 3D scanning preview
│   │   ├── TrueDepthCamera/      # TrueDepth camera handling
│   │   └── IO/                   # File I/O (PLY, SCN)
│   ├── Gallery/                  # 3D Viewer
│   │   ├── GalleryView.swift     
│   │   └── CustomSceneView.swift
│   ├── Convert/                  # File conversion and upload
│   │   ├── ConvertView.swift
│   │   └── ConvertViewModel.swift
│   └── Measure/                  # Measurement data processing
│       └── MeasureViewController.swift
├── Pods/                         # CocoaPods dependencies
└── Podfile                       # CocoaPods configuration
```
