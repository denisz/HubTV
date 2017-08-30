package hub

var IndexHtml = `
<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="UTF-8">
	<title></title>
	<meta name="viewport" content="user-scalable=no, width=device-width">
	<meta name="viewport" content="initial-scale=1.0">
</head>
<body>
	<style>
		body, html {
			height: 100%;
			width: 100%;
			margin: 0;
			background: black;
		}
	</style>

	<video width="100%" height="100%" controls autoplay="autoplay" id="video">
	  <source src="/file" type="video/mp4">Your browser does not support the video tag.
	</video>

	<script type="text/javascript">
		var myVideo = document.getElementById("video");
		myVideo.load();
		myVideo.play();
	</script>
</body>
</html>
`
