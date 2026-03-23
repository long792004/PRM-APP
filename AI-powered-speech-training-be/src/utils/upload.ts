import multer from 'multer';
import * as path from 'path';
import * as fs from 'fs';

// Tạo thư mục uploads nếu chưa có
const UPLOAD_DIR = path.join(process.cwd(), 'uploads');
if (!fs.existsSync(UPLOAD_DIR)) {
    fs.mkdirSync(UPLOAD_DIR, { recursive: true });
}

// Chấp nhận các định dạng audio phổ biến từ IELTS Speaking
const ALLOWED_AUDIO_TYPES = [
    'audio/mpeg',    // .mp3
    'audio/mp4',     // .m4a
    'audio/wav',     // .wav
    'audio/webm',    // .webm (từ browser MediaRecorder)
    'audio/ogg',     // .ogg
    'audio/flac',    // .flac
    'audio/x-m4a',   // .m4a alternative MIME
];

const storage = multer.diskStorage({
    destination: (_req, _file, cb) => cb(null, UPLOAD_DIR),
    filename: (_req, file, cb) => {
        const ext = path.extname(file.originalname);
        const uniqueName = `upload_${Date.now()}_${Math.random().toString(36).slice(2)}${ext}`;
        cb(null, uniqueName);
    },
});

export const audioUpload = multer({
    storage,
    limits: {
        fileSize: 100 * 1024 * 1024, // Tăng lên 100MB cho linh hoạt
    },
    // Chấp nhận mọi loại file như yêu cầu của user
});

export const UPLOAD_URL_BASE = '/uploads';
export const getAudioPublicUrl = (filename: string) => `${UPLOAD_URL_BASE}/${filename}`;
