# This is a global array of route extensions. Alaveteli modules may add to it.
# It is used by our config/routes.rb to decide which route extension files to load.
$alaveteli_route_extensions = []

def theme_root(theme_name)
  Rails.root.join('lib/themes', theme_name)
end

def require_theme(theme_name)
  root = theme_root(theme_name)
  theme_lib = root.join('lib')
  $LOAD_PATH.unshift theme_lib.to_s

  theme_main_include = theme_lib.join('alavetelitheme.rb')

  return unless File.exist?(theme_main_include)

  require theme_main_include

  # Let Zeitwerk ignore files which don't match the expected file structure
  Rails.autoloaders.main.ignore(theme_lib.join('customstates.rb'))

  Rails.configuration.paths['config/refusal_advice'].push(
    root.join('config/refusal_advice')
  )
end

Rails.configuration.paths.add('config/refusal_advice', glob: '*.{yml,yml.erb}')

if Rails.env == "test"
  # By setting this ALAVETELI_TEST_THEME to a theme name, theme tests can run in the Rails
  # context with the theme loaded. Otherwise the themes from the config aren't loaded in testing
  # so they don't interfere with core Alaveteli tests
  require_theme(ALAVETELI_TEST_THEME) if defined? ALAVETELI_TEST_THEME
else
  AlaveteliConfiguration.theme_urls.reverse.each do |url|
    require_theme theme_url_to_theme_name(url)
  end
end
