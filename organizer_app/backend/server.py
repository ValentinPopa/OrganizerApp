from flask import Flask, request, jsonify
import cv2
import numpy as np
from sklearn.cluster import KMeans
from io import BytesIO
from PIL import Image
import colorsys

app = Flask(__name__)

def dominant_color(img, k=3):
    img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
    img = img.reshape((-1, 3))
    kmeans = KMeans(n_clusters=k)
    kmeans.fit(img)
    colors = kmeans.cluster_centers_.astype(int)
    # Alege cea mai frecventă culoare
    labels, counts = np.unique(kmeans.labels_, return_counts=True)
    main_color = colors[labels[np.argmax(counts)]]
    return main_color.tolist()

@app.route('/analyze', methods=['POST'])
def analyze():
    file = request.files['image']
    img = Image.open(file.stream)
    img = np.array(img)

    # Simulare “detectare” cărți: împărțim imaginea în 10 benzi verticale
    h, w, _ = img.shape
    band_width = w // 10
    colors = []
    for i in range(10):
        x1, x2 = i * band_width, (i + 1) * band_width
        sub = img[:, x1:x2]
        colors.append(dominant_color(sub))

    # Sortăm după nuanță
    colors.sort(key=lambda c: colorsys.rgb_to_hsv(c[0]/255, c[1]/255, c[2]/255)[0])
    return jsonify({'colors': colors})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
