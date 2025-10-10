FROM golang:1.25.2-trixie

WORKDIR /convert

RUN go install github.com/gomarkdown/mdtohtml@latest

ENTRYPOINT ["mdtohtml"]
