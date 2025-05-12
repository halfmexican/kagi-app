kagi_app_sources = [
  'main.vala',
  'application.vala',
  'window.vala',
]

kagi_app_deps = [
  config_dep,
  dependency('gtk4'),
  dependency('libadwaita-1', version: '>= 1.4'),
  dependency('webkitgtk-6.0'),
]

blueprints = custom_target('blueprints',
  input: files(
    'gtk/window.blp'
  ),
  output: '.',
  command: [find_program('blueprint-compiler'), 'batch-compile', '@OUTPUT@', '@CURRENT_SOURCE_DIR@', '@INPUT@'],
)
kagi_app_sources += gnome.compile_resources('kagi-app-resources',
  'kagi-app.gresource.xml',
  c_name: 'kagi_app',
  dependencies: blueprints
)

executable('kagi-app', kagi_app_sources,
  dependencies: kagi_app_deps,
  include_directories: config_inc,
       install: true,
)
