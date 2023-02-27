package main

import (
	"context"
	"encoding/csv"
	"fmt"
	"io"
	"log"
	"os"

	texttospeech "cloud.google.com/go/texttospeech/apiv1"
	"cloud.google.com/go/texttospeech/apiv1/texttospeechpb"
)

func execTextToSpeech(text string, output string) {
	// Instantiates a client.
	ctx := context.Background()

	client, err := texttospeech.NewClient(ctx)
	if err != nil {
		log.Fatal(err)
	}
	defer client.Close()

	// Perform the text-to-speech request on the text input with the selected
	// voice parameters and audio file type.
	req := texttospeechpb.SynthesizeSpeechRequest{
		// Set the text input to be synthesized.
		Input: &texttospeechpb.SynthesisInput{
			InputSource: &texttospeechpb.SynthesisInput_Text{Text: text},
		},
		// Build the voice request, select the language code ("en-US") and the SSML
		// voice gender ("neutral").
		Voice: &texttospeechpb.VoiceSelectionParams{
			LanguageCode: "en-US",
			SsmlGender:   texttospeechpb.SsmlVoiceGender_NEUTRAL,
		},
		// Select the type of audio file you want returned.
		AudioConfig: &texttospeechpb.AudioConfig{
			AudioEncoding: texttospeechpb.AudioEncoding_MP3,
		},
	}

	resp, err := client.SynthesizeSpeech(ctx, &req)
	if err != nil {
		log.Fatal(err)
	}

	// The resp's AudioContent is binary.
	filename := output
	// write to file
	err = os.WriteFile(filename, resp.AudioContent, 0644)
	if err != nil {
		log.Fatal(err)
	}
	fmt.Printf("Audio content written to file: %v\n", filename)
}

func main() {
	// if len(os.Args) != 3 {
	// 	log.Fatalf("Usage: %s <text-to-speech> <output.mp3>", os.Args[0])
	// }
	// text := os.Args[1]
	// output := os.Args[2]

	if len(os.Args) != 2 {
		log.Fatalf("Usage: %s <text-to-speech.csv>", os.Args[0])
	}

	csvFile, err := os.Open(os.Args[1])
	if err != nil {
		log.Fatal(err)
	}
	defer csvFile.Close()

	r := csv.NewReader(csvFile)
	for {
		record, err := r.Read()
		if err == io.EOF {
			break
		}
		if err != nil {
			log.Fatal(err)
		}
		// exec with record
		text := record[0]
		output := record[1]
		if text == "" || output == "" {
			break
		}
		execTextToSpeech(text, output)
	}

}
