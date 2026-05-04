use zxingcpp::{read, BarcodeFormat, ImageView, ImageFormat};
use nokhwa::utils::{CameraIndex, ApiBackend, RequestedFormat, RequestedFormatType};
use nokhwa::query;
use nokhwa::Camera;
use crate::frb_generated::StreamSink;

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

pub struct Point {
    pub x: i32,
    pub y: i32,
}

pub struct BarcodeResult {
    pub text: String,
    pub bytes: Vec<u8>,
    pub format: String,
    pub top_left: Point,
    pub top_right: Point,
    pub bottom_right: Point,
    pub bottom_left: Point,
}

pub struct Frame {
    pub bytes: Vec<u8>,
    pub width: u32,
    pub height: u32,
}

pub struct CameraInfo {
    pub index: u32,
    pub name: String,
}

#[flutter_rust_bridge::frb(sync)]
pub fn available_cameras() -> Result<Vec<CameraInfo>, String> {
    let devices = query(ApiBackend::Auto).map_err(|e| e.to_string())?;
    Ok(devices
        .into_iter()
        .map(|d| CameraInfo {
            index: match d.index() {
                CameraIndex::Index(i) => *i,
                _ => 0,
            },
            name: d.human_name(),
        })
        .collect())
}

#[flutter_rust_bridge::frb(sync)]
pub fn start_scan(
    result_sink: StreamSink<Vec<BarcodeResult>>,
    frame_sink: StreamSink<Frame>,
    index: u32,
) -> Result<(), String> {
    let camera_index = CameraIndex::Index(index);
    let requested = RequestedFormat::new::<nokhwa::pixel_format::RgbAFormat>(RequestedFormatType::AbsoluteHighestFrameRate);
    
    let (width, height) = {
        let camera = Camera::new(camera_index.clone(), requested.clone()).map_err(|e| e.to_string())?;
        let cf = camera.camera_format();
        (cf.width(), cf.height())
    };

    let mut threaded_camera = nokhwa::threaded::CallbackCamera::new(camera_index, requested, move |frame| {
        let bytes = frame.buffer();
        
        // Send frame for preview
        let _ = frame_sink.add(Frame {
            bytes: bytes.to_vec(),
            width,
            height,
        });

        // Scan for barcodes
        let iv = ImageView::from_slice(bytes, width as i32, height as i32, ImageFormat::RGBA).unwrap();
        if let Ok(results) = read().from(&iv) {
            if !results.is_empty() {
                let barcodes = results.into_iter().map(|res| BarcodeResult {
                    text: res.text(),
                    bytes: res.bytes(),
                    format: res.format().to_string(),
                    top_left: Point { x: res.position().top_left.x, y: res.position().top_left.y },
                    top_right: Point { x: res.position().top_right.x, y: res.position().top_right.y },
                    bottom_right: Point { x: res.position().bottom_right.x, y: res.position().bottom_right.y },
                    bottom_left: Point { x: res.position().bottom_left.x, y: res.position().bottom_left.y },
                }).collect();
                
                let _ = result_sink.add(barcodes);
            }
        }
    }).map_err(|e| e.to_string())?;

    threaded_camera.open_stream().map_err(|e| e.to_string())?;
    
    // Leak the camera to keep it running
    std::mem::forget(threaded_camera);

    Ok(())
}

#[flutter_rust_bridge::frb(sync)]
pub fn analyze_image(path: String) -> Result<Vec<BarcodeResult>, String> {
    let img = image::open(&path).map_err(|e| e.to_string())?;
    let rgb = img.to_rgb8();
    let width = rgb.width() as i32;
    let height = rgb.height() as i32;
    
    let iv = ImageView::from_slice(&rgb, width, height, ImageFormat::RGB)
        .map_err(|e| e.to_string())?;
    
    let results = read()
        .from(&iv)
        .map_err(|e| e.to_string())?;
    
    let mut barcodes = Vec::new();
    for res in results {
        barcodes.push(BarcodeResult {
            text: res.text(),
            bytes: res.bytes(),
            format: res.format().to_string(),
            top_left: Point { x: res.position().top_left.x, y: res.position().top_left.y },
            top_right: Point { x: res.position().top_right.x, y: res.position().top_right.y },
            bottom_right: Point { x: res.position().bottom_right.x, y: res.position().bottom_right.y },
            bottom_left: Point { x: res.position().bottom_left.x, y: res.position().bottom_left.y },
        });
    }
    
    Ok(barcodes)
}

#[flutter_rust_bridge::frb(sync)]
pub fn analyze_bytes(
    bytes: Vec<u8>,
    width: i32,
    height: i32,
    format: String,
) -> Result<Vec<BarcodeResult>, String> {
    let zxing_format = match format.as_str() {
        "rgb" => ImageFormat::RGB,
        "rgba" => ImageFormat::RGBA,
        "bgra" => ImageFormat::BGRA,
        "luma" => ImageFormat::Lum,
        _ => return Err(format!("Unsupported format: {}", format)),
    };

    let iv = ImageView::from_slice(&bytes, width, height, zxing_format)
        .map_err(|e| e.to_string())?;

    let results = read()
        .from(&iv)
        .map_err(|e| e.to_string())?;

    let mut barcodes = Vec::new();
    for res in results {
        barcodes.push(BarcodeResult {
            text: res.text(),
            bytes: res.bytes(),
            format: res.format().to_string(),
            top_left: Point { x: res.position().top_left.x, y: res.position().top_left.y },
            top_right: Point { x: res.position().top_right.x, y: res.position().top_right.y },
            bottom_right: Point { x: res.position().bottom_right.x, y: res.position().bottom_right.y },
            bottom_left: Point { x: res.position().bottom_left.x, y: res.position().bottom_left.y },
        });
    }

    Ok(barcodes)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_analyze_image() {
        let res = analyze_image("../test_qr.png".to_string());
        assert!(res.is_ok());
        let barcodes = res.unwrap();
        assert_eq!(barcodes.len(), 1);
        assert_eq!(barcodes[0].text, "scanner_plus_test");
        assert_eq!(barcodes[0].format, "QRCode");
    }
}
