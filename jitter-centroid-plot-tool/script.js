// script.js

// Grab references to DOM elements once on load
const dropZone   = document.getElementById("dropZone");
const fileInput  = document.getElementById("csvFile");
const downloadBtn= document.getElementById("downloadBtn");

/* =========================
   1) Enable dragging anywhere
   ========================= */

// Prevent the browser from opening files by default
document.addEventListener("dragover", e => {
  e.preventDefault();
});
document.addEventListener("drop", e => {
  e.preventDefault();
  // Grab the first dropped file
  const file = e.dataTransfer.files[0];
  // Only proceed if it's a CSV
  if (file && file.name.toLowerCase().endsWith(".csv")) {
    handleFile(file);
  } else {
    alert("Please drop a CSV file.");
  }
});

/* =========================
   2) Setup the “drop zone” UI
   ========================= */

// Clicking the drop zone opens the hidden file picker
dropZone.addEventListener("click", () => fileInput.click());

// When you drag *over* the drop zone, visually highlight it
dropZone.addEventListener("dragover", e => {
  e.preventDefault();
  dropZone.classList.add("dragover");
});

// Remove highlight when dragging leaves the drop zone
dropZone.addEventListener("dragleave", () => {
  dropZone.classList.remove("dragover");
});

// Handle a drop *on* the drop zone itself
dropZone.addEventListener("drop", e => {
  e.preventDefault();
  dropZone.classList.remove("dragover");
  const file = e.dataTransfer.files[0];
  if (file && file.name.toLowerCase().endsWith(".csv")) {
    handleFile(file);
  } else {
    alert("Please drop a CSV file.");
  }
});

// Fallback: if the user chooses via the file picker
fileInput.addEventListener("change", e => {
  if (e.target.files[0]) {
    handleFile(e.target.files[0]);
  }
});

/* =========================
   3) Read, parse, and plot
   ========================= */

// Kick off reading & parsing
function handleFile(file) {
  const reader = new FileReader();
  // When file is loaded, send its text to parseCSVAndPlot
  reader.onload = e => parseCSVAndPlot(e.target.result);
  reader.readAsText(file);
}

// Parse the CSV text, extract Centroid X/Y, and plot with Plotly
function parseCSVAndPlot(csv) {
  // Split into lines & headers
  const lines   = csv.trim().split("\n");
  const headers = lines[0].split(",");

  // Find which columns are “Centroid X” and “Centroid Y”
  const xIndex = headers.findIndex(h => h.trim().toLowerCase() === "centroid x");
  const yIndex = headers.findIndex(h => h.trim().toLowerCase() === "centroid y");
  const xs = [], ys = [];

  // Walk each subsequent line
  for (let i = 1; i < lines.length; i++) {
    const row = lines[i].split(",");
    // Skip rows too short to contain our columns
    if (row.length <= Math.max(xIndex, yIndex)) continue;
    const x = parseFloat(row[xIndex]);
    const y = parseFloat(row[yIndex]);
    // Only keep numeric rows
    if (!isNaN(x) && !isNaN(y)) {
      xs.push(x);
      ys.push(y);
    }
  }

  // If nothing valid found, warn and abort
  if (!xs.length) {
    alert("No valid Centroid X/Y data found.");
    return;
  }

  // Build the Plotly trace for raw data points
  const tracePoints = {
    x: xs,
    y: ys,
    mode: "markers",
    type: "scatter",
    name: "Data Points"
  };

  // Layout with grid turned on
  const layout = {
    title: "Centroid X vs. Centroid Y",
    xaxis: { title: "Centroid X", showgrid: true, gridwidth: 1, gridcolor: "lightgrey" },
    yaxis: { title: "Centroid Y", showgrid: true, gridwidth: 1, gridcolor: "lightgrey" }
  };

  // Render into the #plot div
  Plotly.newPlot("plot", [tracePoints], layout);

  // Show and wire up the “Download” button
  downloadBtn.style.display = "inline-block";
  downloadBtn.onclick = () => {
    Plotly.downloadImage("plot", {
      format: "png",
      filename: "jitter_bug_centroid_plot"
    });
  };
}
