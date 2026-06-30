package conf

import (
	"fmt"
	"strings"
	"time"

	"github.com/spf13/viper"
)

type Config struct {
	App  AppConfig  `mapstructure:"app"`
	HTTP HTTPConfig `mapstructure:"http"`
	Log  LogConfig  `mapstructure:"log"`
}

type AppConfig struct {
	Name    string `mapstructure:"name"`
	RunMode string `mapstructure:"run_mode"`
}

type HTTPConfig struct {
	Host         string `mapstructure:"host"`
	Port         int    `mapstructure:"port"`
	ReadTimeout  string `mapstructure:"read_timeout"`
	WriteTimeout string `mapstructure:"write_timeout"`
	IdleTimeout  string `mapstructure:"idle_timeout"`
}

func (c HTTPConfig) Address() string {
	return fmt.Sprintf("%s:%d", c.Host, c.Port)
}

func (c HTTPConfig) ReadTimeoutDuration() time.Duration {
	return parseDuration(c.ReadTimeout, 5*time.Second)
}

func (c HTTPConfig) WriteTimeoutDuration() time.Duration {
	return parseDuration(c.WriteTimeout, 10*time.Second)
}

func (c HTTPConfig) IdleTimeoutDuration() time.Duration {
	return parseDuration(c.IdleTimeout, 30*time.Second)
}

type LogConfig struct {
	Level     string `mapstructure:"level"`
	Format    string `mapstructure:"format"`
	AddSource bool   `mapstructure:"add_source"`
}

func Load(configPath, runMode string) (Config, error) {
	if runMode == "" {
		runMode = "dev"
	}

	if configPath == "" {
		configPath = fmt.Sprintf("etc/config.%s.yaml", runMode)
	}

	v := viper.New()
	v.SetConfigFile(configPath)
	v.SetConfigType("yaml")
	v.SetEnvPrefix("GO_REACT_OPENSPEC_STARTER")
	v.SetEnvKeyReplacer(strings.NewReplacer(".", "_"))
	v.AutomaticEnv()

	setDefaults(v, runMode)

	if err := v.ReadInConfig(); err != nil {
		return Config{}, fmt.Errorf("read config file %q: %w", configPath, err)
	}

	var cfg Config
	if err := v.Unmarshal(&cfg); err != nil {
		return Config{}, fmt.Errorf("unmarshal config: %w", err)
	}

	return cfg, nil
}

func setDefaults(v *viper.Viper, runMode string) {
	v.SetDefault("app.name", "go-react-openspec-starter")
	v.SetDefault("app.run_mode", runMode)
	v.SetDefault("http.host", "0.0.0.0")
	v.SetDefault("http.port", 8080)
	v.SetDefault("http.read_timeout", "5s")
	v.SetDefault("http.write_timeout", "10s")
	v.SetDefault("http.idle_timeout", "30s")
	v.SetDefault("log.level", "info")
	v.SetDefault("log.format", "json")
	v.SetDefault("log.add_source", false)
}

func parseDuration(raw string, fallback time.Duration) time.Duration {
	if raw == "" {
		return fallback
	}

	duration, err := time.ParseDuration(raw)
	if err != nil {
		return fallback
	}

	return duration
}
