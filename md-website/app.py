from flask import Flask, render_template, request, jsonify, abort
from google.cloud import pubsub_v1
from google.api_core import exceptions
import os
import logging


logging.basicConfig(level=logging.INFO)
gcs_mount = os.getenv("GCS_MOUNTPOINT")


app = Flask(__name__)

@app.route('/')
def index():
    return render_template('index.html', title='Home')


@app.route('/api/mdconvert', methods=['POST'])
def md_converter():
    # validate json in request
    if not request.is_json:
        return jsonify({"error": "Missing JSON in request"}), 400

    data = request.get_json()
    markdown = data.get('markdown')

    if not markdown:
        return jsonify({"error", "Missing 'markdown' field"}), 400

    
    # submit pubsub message
    project_id = 'still-tower-474715-c6'
    topic_id = 'mdconversions'
    bucket_name = os.getenv("BUCKETNAME")

    publisher = pubsub_v1.PublisherClient()
    topic_path = publisher.topic_path(project_id, topic_id)

    data = markdown.encode('utf-8')

    try:
        future = publisher.publish(
            topic_path, data=data, bucketname=bucket_name
        )

        message_id = future.result()
        logging.info(f'Published message with ID: {message_id}')

        return jsonify({
            "status": "success",
            "message_id": message_id,
            "listen_endpoint": f'/api/retrieve/{message_id}.html'
        })

    except exceptions.GoogleAPICallError as e:
        logging.error(f'Google API error during publish: {e}')
        return jsonify({"status": "error"})

    except Exception as e:
        logging.error(f'An unexpected error occured during publish: {e}')
        return jsonify({"status": "error"})

    finally:
        publisher.transport.close()

@app.route('/api/retrieve/<filename>', methods=['GET'])
def retrieve_html(filename):
    file_path = os.path.join(gcs_mount, filename)

    if not os.path.abspath(file_path).startswith(gcs_mount):
        abort(403)

    if os.path.exists(file_path) and os.path.isfile(file_path):
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                html = f.read()
                return jsonify({
                    "status": "success",
                    "filename": filename,
                    "html": html
                })

        except Exception as e:
            return jsonify({"error": f"Could not read file: {str(e)}"}), 500

    else:
        return jsonify({"error": f"File '{filename}' not found."}), 404


if __name__ == '__main__':
    if not os.path.exists(gcs_mount):
        logging.error('GCS mount is not present. Refusing to start flask')
    else:
        app.run()
