package p

import (
	"context"
	"encoding/json"
	"log"
	"os"
	"fmt"
	"errors"
  "github.com/gomarkdown/markdown"
	"github.com/gomarkdown/markdown/html"
	"github.com/gomarkdown/markdown/parser"
	"cloud.google.com/go/storage"
)

type PubSubMessage struct {
	Data []byte `json:"data"`
}

func ConvertMarkdown(md []byte) []byte {
  // create markdown parser with extensions
	extensions := parser.CommonExtensions | parser.AutoHeadingIDs | parser.NoEmptyLineBeforeBlock
	p := parser.NewWithExtensions(extensions)
	doc := p.Parse(md)

  // create HTML renderer with extensions
	htmlFlags := html.CommonFlags | html.HrefTargetBlank
	opts := html.RendererOptions{Flags: htmlFlags}
	renderer := html.NewRenderer(opts)

	return markdown.Render(doc, renderer)
}

func UploadToGCS(html []byte, jobid string) error {
	projectID := "your-gcp-project-id"
	bucketName := "your-gcs-bucket-name"
	fileName := fmt.Sprintf("%s.html", jobid)

	ctx := context.Background()

	client, err := storage.NewClient(ctx, projectID)
	if err != nil {
		log.Fatalf("Failed to create client: %v", err)
	}
	defer client.Close()

	wc := client.Bucket(bucketName).Object(fileName).NewWriter(ctx)

	// Optional: Set content type and metadata
	wc.ContentType = "text/html; charset=utf-8"

	if _, err = wc.Write(html); err != nil {
		return fmt.Errorf("Failed to write data to GCS: %v", err)
	}

	if err := wc.Close(); err != nil {
		return fmt.Errorf("Failed to close GCS writer: %v", err)
	}

	fmt.Printf("Successfully wrote data to gs://%s/%s\n", bucketName, fileName)

	return nil
}

func ConsumePubSub(ctx context.Context, m PubSubMessage) error {
	var data struct {
		Markdown []byte `json:"markdown"`
    JobID string `json:"jobid"`
	}

	if m.Data != nil {
		if err := json.Unmarshal(m.Data, &data); err != nil {
			log.Printf("json.Unmarshal failed: %v", err)
		}
	}

  renderedHTML := ConvertMarkdown(data.Markdown)
  err := UploadToGCS(renderedHTML, data.JobID)
	if err != nil {
		return fmt.Errorf("Error uploading %s: %v\n", data.JobID, err)
	} else {
    fmt.Println("%s uploaded successfully.", data.JobID)
	}

	return nil
}
