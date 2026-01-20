package audio

import (
	"context"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/go-audio/wav"
	mp3 "github.com/hajimehoshi/go-mp3"
)

const (
	// TargetSampleRate is the target sample rate for normalization (44.1kHz)
	TargetSampleRate = 44100
	// TargetChannels is the target number of channels (mono)
	TargetChannels = 1
	// TargetBitDepth is the target bit depth (16-bit)
	TargetBitDepth = 16
)

// DecodeAudioToPCM decodes an audio file to normalized PCM
func DecodeAudioToPCM(ctx context.Context, filePath string) ([]int16, error) {
	ext := strings.ToLower(filepath.Ext(filePath))

	switch ext {
	case ".mp3":
		return decodeMP3(ctx, filePath)
	case ".wav":
		return decodeWAV(ctx, filePath)
	case ".flac", ".aac", ".ogg", ".m4a":
		// Use ffmpeg for formats not directly supported
		return decodeWithFFmpeg(ctx, filePath)
	default:
		// Try ffmpeg as fallback
		return decodeWithFFmpeg(ctx, filePath)
	}
}

// decodeMP3 decodes MP3 file to PCM
func decodeMP3(ctx context.Context, filePath string) ([]int16, error) {
	return decodeMP3Hajimehoshi(ctx, filePath)
}

// decodeMP3Hajimehoshi uses hajimehoshi/go-mp3 (pure Go)
func decodeMP3Hajimehoshi(ctx context.Context, filePath string) ([]int16, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to open file: %w", err)
	}
	defer file.Close()

	dec, err := mp3.NewDecoder(file)
	if err != nil {
		return nil, fmt.Errorf("failed to create MP3 decoder: %w", err)
	}

	// Read all samples
	buf := make([]byte, 4096)
	var samples []byte
	for {
		select {
		case <-ctx.Done():
			return nil, ctx.Err()
		default:
		}

		n, err := dec.Read(buf)
		if n > 0 {
			samples = append(samples, buf[:n]...)
		}
		if err != nil {
			break
		}
	}

	// Convert to int16 (assuming 16-bit samples)
	pcm := make([]int16, len(samples)/2)
	for i := 0; i < len(samples); i += 2 {
		if i+1 < len(samples) {
			pcm[i/2] = int16(samples[i]) | int16(samples[i+1])<<8
		}
	}

	// MP3 decoder doesn't provide sample rate/channels info easily
	// Assume 44.1kHz stereo and resample
	return resampleToTarget(pcm, 44100, TargetSampleRate, 2, TargetChannels)
}

// decodeWAV decodes WAV file to PCM
func decodeWAV(ctx context.Context, filePath string) ([]int16, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return nil, fmt.Errorf("failed to open file: %w", err)
	}
	defer file.Close()

	decoder := wav.NewDecoder(file)
	if !decoder.IsValidFile() {
		return nil, fmt.Errorf("invalid WAV file")
	}

	format := decoder.Format()
	if format == nil {
		return nil, fmt.Errorf("failed to get WAV format")
	}

	// Read full PCM buffer
	pcmBuf, err := decoder.FullPCMBuffer()
	if err != nil {
		return nil, fmt.Errorf("failed to read PCM buffer: %w", err)
	}

	// Convert int to int16
	pcm := make([]int16, len(pcmBuf.Data))
	for i, sample := range pcmBuf.Data {
		// Clamp to int16 range
		if sample > 32767 {
			sample = 32767
		} else if sample < -32768 {
			sample = -32768
		}
		pcm[i] = int16(sample)
	}

	return resampleToTarget(pcm, int(format.SampleRate), TargetSampleRate, int(format.NumChannels), TargetChannels)
}

// decodeWithFFmpeg uses ffmpeg to decode audio (fallback for unsupported formats)
func decodeWithFFmpeg(ctx context.Context, filePath string) ([]int16, error) {
	// Check if ffmpeg is available
	if _, err := exec.LookPath("ffmpeg"); err != nil {
		return nil, fmt.Errorf("ffmpeg not found: %w", err)
	}

	// Create temporary output file
	tmpFile := filepath.Join(os.TempDir(), fmt.Sprintf("cotune_pcm_%d.raw", os.Getpid()))
	defer os.Remove(tmpFile)

	// Use ffmpeg to convert to raw PCM
	cmd := exec.CommandContext(ctx, "ffmpeg",
		"-i", filePath,
		"-f", "s16le", // 16-bit signed little-endian
		"-ar", "44100", // Sample rate 44.1kHz
		"-ac", "1", // Mono
		"-y", // Overwrite output
		tmpFile,
	)

	if err := cmd.Run(); err != nil {
		return nil, fmt.Errorf("ffmpeg conversion failed: %w", err)
	}

	// Read PCM data
	data, err := os.ReadFile(tmpFile)
	if err != nil {
		return nil, fmt.Errorf("failed to read PCM file: %w", err)
	}

	// Convert bytes to int16
	pcm := make([]int16, len(data)/2)
	for i := 0; i < len(data); i += 2 {
		if i+1 < len(data) {
			pcm[i/2] = int16(data[i]) | int16(data[i+1])<<8
		}
	}

	return pcm, nil
}

// resampleToTarget resamples PCM data to target sample rate and channels
// Simple linear interpolation resampling
func resampleToTarget(pcm []int16, srcRate, dstRate, srcChannels, dstChannels int) ([]int16, error) {
	if srcRate == dstRate && srcChannels == dstChannels {
		return pcm, nil
	}

	// Convert to mono if needed
	if srcChannels > dstChannels {
		mono := make([]int16, len(pcm)/srcChannels)
		for i := 0; i < len(mono); i++ {
			var sum int32
			for ch := 0; ch < srcChannels; ch++ {
				sum += int32(pcm[i*srcChannels+ch])
			}
			mono[i] = int16(sum / int32(srcChannels))
		}
		pcm = mono
	}

	// Resample if needed
	if srcRate != dstRate {
		ratio := float64(dstRate) / float64(srcRate)
		resampled := make([]int16, int(float64(len(pcm))*ratio))
		for i := 0; i < len(resampled); i++ {
			srcIdx := float64(i) / ratio
			idx0 := int(srcIdx)
			idx1 := idx0 + 1
			if idx1 >= len(pcm) {
				idx1 = len(pcm) - 1
			}

			// Linear interpolation
			t := srcIdx - float64(idx0)
			val := float64(pcm[idx0])*(1-t) + float64(pcm[idx1])*t
			resampled[i] = int16(val)
		}
		pcm = resampled
	}

	return pcm, nil
}
