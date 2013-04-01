module.exports = (grunt) ->

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-contrib-qunit'
  grunt.loadNpmTasks 'grunt-contrib-uglify'
  grunt.loadNpmTasks 'grunt-contrib-jade'
  grunt.loadNpmTasks 'grunt-contrib-sass'

  # Project configuration.
  grunt.initConfig
    pkg: grunt.file.readJSON 'rondell.jquery.json'
    meta:
      banner: '/*!\n' +
        'jQuery <%= pkg.name %> plugin\n' +
        '@name jquery.<%= pkg.name %>.js\n' +
        '@author Sebastian Helzle (sebastian@helzle.net or @sebobo)\n' +
        '@version <%= pkg.version %>\n' +
        '@date <%= grunt.template.today("yyyy-mm-dd") %>\n' +
        '@category jQuery plugin\n' +
        '@copyright (c) 2009-2013 Sebastian Helzle (www.sebastianhelzle.net)\n' +
        '@license Licensed under the MIT (http://www.opensource.org/licenses/mit-license.php) license.\n' +
        '*/\n'
    qunit:
      files: ['tests/**/*.html']
    growl:
      coffee:
        title: 'grunt'
        message: 'Compiled coffeescript'
      jade:
        title: 'grunt'
        message: 'Compiled jade'
      sass:
        title: 'grunt'
        message: 'Compiled sass'
    coffee:
      compile:
        options:
          bare: true
        files:
          'dist/jquery.rondell.js': ['src/coffee/*.coffee']
    watch:
      coffee:
        files: 'src/coffee/**/*.coffee',
        tasks: ['coffee:compile']#, 'growl:coffee']
      jade:
        files: 'src/jade/**/*.jade'
        tasks: ['jade:compile']#, 'growl:jade']
      sass:
        files: 'src/scss/**/*.scss'
        tasks: ['sass:compile']#, 'growl:sass']
    jade:
      compile:
        options:
          pretty: true
        data:
          pluginVersion: '<%= pkg.version %>'
        files:
          'index.html': 'src/jade/index.jade'
          'tests/tests.html': 'src/jade/tests/tests.jade'
          'examples/carousel.html': 'src/jade/examples/carousel.jade'
          'examples/gallery.html': 'src/jade/examples/gallery.jade'
          'examples/installation.html': 'src/jade/examples/installation.jade'
          'examples/options.html': 'src/jade/examples/options.jade'
          'examples/pages.html': 'src/jade/examples/pages.jade'
          'examples/scroller.html': 'src/jade/examples/scroller.jade'
          'examples/slider.html': 'src/jade/examples/slider.jade'
          'examples/thumbnails.html': 'src/jade/examples/thumbnails.jade'
          'examples/changelog.html': 'src/jade/examples/changelog.jade'
    sass:
      dist:
        options:
          style: 'compressed'
          compass: true
        files:
          'dist/jquery.rondell.min.css': 'src/scss/jquery.<%= pkg.name %>.scss'
      compile:
        options:
          style: 'expanded'
          compass: true
        files:
          'examples/screen.css': 'src/scss/screen.scss'
          'dist/jquery.rondell.css': 'src/scss/jquery.rondell.scss'
    uglify:
      dist:
        options:
          banner: '<%= meta.banner %>'
        files:
          'dist/jquery.rondell.min.js': ['dist/jquery.rondell.js']

  # Default task which watches jade, sass and coffee.
  grunt.registerTask 'default', ['watch']
  # Release task to run tests then minify js and css
  grunt.registerTask 'release', ['qunit', 'uglify', 'sass:dist']
