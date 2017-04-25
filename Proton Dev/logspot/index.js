var express = require('express');
var multer  = require('multer');
var upload = multer({ dest: 'uploads/' });
var app = express();

app.post('/', upload.single('file'), function(req, res) {
	console.log(req.file);
	res.status(200).end();
});

app.listen(3000, function () {
});
