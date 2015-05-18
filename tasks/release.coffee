gulp   			= require 'gulp'
GitHubApi  	= require 'github'
fs 					= require 'fs-extra'
async 			= require 'async'
glob 				= require 'glob'
path 				= require 'path'

pkg = require '../package.json'

# Setup Github API
github = new GitHubApi {
  version: "3.0.0"
  debug: true
  protocol: "https"
  timeout: 5000
  headers: {
    "user-agent": "Championify-Gulp-Release"
  }
}

github.authenticate {
  type: 'oauth'
  token: process.env.GITHUB_TOKEN
}

gulp.task 'move-asar', (cb) ->
  fs.copy './tmp/app.asar', './releases/update.asar', -> cb()


gulp.task 'github-release', (cb) ->
  async.waterfall [
  	# Create release draft
  	(step) ->
  		fs.readFile './CHANGELOG.md', {encoding: 'utf8'}, (err, changelog) ->
  			body = changelog.split(/<a name="*.*.*" \/>/g)[1]

  			create_release = {
  				owner: 'dustinblackman'
  				repo: 'Championify'
  				tag_name: pkg.version
  				draft: true
  				name: 'Championify '+pkg.version
  				body: body
  			}
  			github.releases.createRelease create_release, (err, release) ->
  				step err, release.id

  	# Upload Assets
  	(release_id, step) ->
  		glob './releases/*', (err, files) ->
  			async.eachSeries files, (file_path, acb) ->
  				console.log 'Uploading: ' + file_path
  				upload_file = {
  					owner: 'dustinblackman',
  					repo: 'Championify',
  					id: release_id,
  					name: path.basename(file_path)
  					filePath: file_path
  				}

  				github.releases.uploadAsset upload_file, (err, done) ->
  					console.log done
  					acb null

  			, (err) ->
  				console log err if err
  				step err

  ], ->
    cb()
