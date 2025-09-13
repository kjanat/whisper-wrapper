package main

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"syscall"

	"github.com/spf13/cobra"
)

// WHISPER_BIN environment variable can override the underlying whisper executable.
const whisperBinEnv = "WHISPER_BIN"

var rootCmd = &cobra.Command{
	Use:                "whisper-wrapper [flags] audio [audio...]",
	Short:              "Wrapper for OpenAI whisper CLI with shell completions",
	SilenceUsage:       true,
	DisableFlagParsing: true, // pass all flags and args through to whisper
	Args:               cobra.ArbitraryArgs,
	ValidArgsFunction:  audioCompletion,
	RunE: func(cmd *cobra.Command, _ []string) error {
		// Pass-through execution of the underlying whisper binary
		bin := os.Getenv(whisperBinEnv)
		if bin == "" {
			bin = "whisper"
		}

		args := os.Args[1:]
		if len(args) == 0 {
			args = []string{"-h"}
		}

		if _, err := exec.LookPath(bin); err != nil {
			return fmt.Errorf("could not find '%s' in PATH (or via %s)", bin, whisperBinEnv)
		}

		c := exec.Command(bin, args...)
		c.Stdin = os.Stdin
		c.Stdout = os.Stdout
		c.Stderr = os.Stderr
		if err := c.Run(); err != nil {
			return err
		}
		return nil
	},
}

func main() {
	// Define known whisper flags for completion purposes only.
	// These won't be parsed at runtime (DisableFlagParsing=true), but will appear in shell completions.
	f := rootCmd.PersistentFlags()
	f.String("model", "", "whisper model size (e.g. tiny, base, small, medium, large)")
	f.String("model_dir", "", "directory to cache/load models")
	f.String("device", "", "compute device (e.g. cpu, cuda)")
	f.String("output_dir", "", "directory to store outputs")
	f.String("output_format", "txt", "output format: txt, vtt, srt, tsv, json, all")
	f.Bool("verbose", false, "print progress and debug information")
	f.String("task", "transcribe", "task: transcribe or translate")
	f.String("language", "", "input language (code or name)")
	f.Float32("temperature", 0.0, "initial temperature")
	f.Int("best_of", 5, "number of candidates for sampling")
	f.Int("beam_size", 5, "beam size for beam search")
	f.Float32("patience", 1.0, "beam search patience")
	f.Float32("length_penalty", 1.0, "length penalty for beam search")
	f.String("suppress_tokens", "-1", "comma-separated token ids to suppress")
	f.String("initial_prompt", "", "optional initial prompt")
	f.Bool("carry_initial_prompt", false, "carry initial prompt between segments")
	f.Bool("condition_on_previous_text", true, "condition decoding on previous text")
	f.Bool("fp16", true, "use FP16 where available")
	f.Float32("temperature_increment_on_fallback", 0.2, "temperature increment on fallback")
	f.Float32("compression_ratio_threshold", 2.4, "if gzip compression ratio is above this value, treat as failure")
	f.Float32("logprob_threshold", -1.0, "if average log probability is below this value, treat as failure")
	f.Float32("no_speech_threshold", 0.6, "if no speech probability is above this value and the decoded text is empty, treat as silence")
	f.Bool("word_timestamps", false, "extract word-level timestamps")
	f.String("prepend_punctuations", "", "prepend punctuations for word timestamps")
	f.String("append_punctuations", "", "append punctuations for word timestamps")
	f.Bool("highlight_words", false, "highlight words in VTT/SRT outputs")
	f.Int("max_line_width", 0, "maximum line width for VTT/SRT outputs")
	f.Int("max_line_count", 0, "maximum line count for VTT/SRT outputs")
	f.Int("max_words_per_line", 0, "maximum words per line for VTT/SRT outputs")
	f.Int("threads", 0, "number of threads to use")
	f.String("clip_timestamps", "-1", "timestamps to clip, e.g. 0:30,15:00")
	f.Float32("hallucination_silence_threshold", 0.5, "silence threshold to split hallucinations")

	// Value completions for some flags
	_ = rootCmd.RegisterFlagCompletionFunc("output_format", enumCompletion("txt", "vtt", "srt", "tsv", "json", "all"))
	_ = rootCmd.RegisterFlagCompletionFunc("task", enumCompletion("transcribe", "translate"))
	_ = rootCmd.RegisterFlagCompletionFunc("language", enumCompletion(append(languageCodes, languageNames...)...))
	_ = rootCmd.RegisterFlagCompletionFunc("model", enumCompletion("tiny", "tiny.en", "base", "base.en", "small", "small.en", "medium", "medium.en", "large", "large-v1", "large-v2", "large-v3", "large-v3-turbo"))
	_ = rootCmd.RegisterFlagCompletionFunc("device", enumCompletion("cpu", "cuda", "cuda:0", "mps"))
	_ = rootCmd.RegisterFlagCompletionFunc("model_dir", dirCompletion)
	_ = rootCmd.RegisterFlagCompletionFunc("output_dir", dirCompletion)

	// Add the completion subcommand
	rootCmd.AddCommand(newCompletionCmd())

	if err := rootCmd.Execute(); err != nil {
		// Propagate exit status from underlying command if possible
		var exitErr *exec.ExitError
		if errors.As(err, &exitErr) {
			if status, ok := exitErr.Sys().(syscall.WaitStatus); ok {
				os.Exit(status.ExitStatus())
				return
			}
		}
		fmt.Fprintf(os.Stderr, "whisper-wrapper: %v\n", err)
		os.Exit(1)
	}
}

func enumCompletion(values ...string) func(*cobra.Command, []string, string) ([]string, cobra.ShellCompDirective) {
	return func(_ *cobra.Command, _ []string, _ string) ([]string, cobra.ShellCompDirective) {
		return values, cobra.ShellCompDirectiveNoFileComp
	}
}

func audioCompletion(_ *cobra.Command, _ []string, _ string) ([]string, cobra.ShellCompDirective) {
	// Let the shell complete files but filter by typical audio/video extensions supported by whisper/ffmpeg
	exts := []string{
		// Audio
		".wav", ".mp3", ".m4a", ".aac", ".flac", ".ogg", ".opus", ".wma", ".aiff", ".aif", ".alac", ".mpga",
		// Video (commonly supported by ffmpeg)
		".mp4", ".m4v", ".mov", ".mkv", ".webm", ".avi", ".wmv", ".flv", ".ts", ".m2ts", ".mts", ".3gp", ".mpeg", ".mpg", ".mpe",
	}
	return exts, cobra.ShellCompDirectiveFilterFileExt
}

func newCompletionCmd() *cobra.Command {
	cmd := &cobra.Command{
		Use:   "completion [bash|zsh|fish|powershell]",
		Short: "Generate shell completion scripts",
		Long: "To load completions:\n\n" +
			"Bash:\n  source <(whisper-wrapper completion bash)\n\n" +
			"Zsh:\n  whisper-wrapper completion zsh > ${fpath[1]}/_whisper-wrapper\n\n" +
			"Fish:\n  whisper-wrapper completion fish | source\n\n" +
			"PowerShell:\n  whisper-wrapper completion powershell | Out-String | Invoke-Expression\n\n",
		Args: cobra.MatchAll(cobra.ExactArgs(1), cobra.OnlyValidArgs),
		ValidArgs: []string{
			"bash", "zsh", "fish", "powershell",
		},
		RunE: func(cmd *cobra.Command, args []string) error {
			switch args[0] {
			case "bash":
				return rootCmd.GenBashCompletion(os.Stdout)
			case "zsh":
				// Use no-description template for better compatibility
				return rootCmd.GenZshCompletionNoDesc(os.Stdout)
			case "fish":
				return rootCmd.GenFishCompletion(os.Stdout, true)
			case "powershell":
				return rootCmd.GenPowerShellCompletionWithDesc(os.Stdout)
			default:
				return fmt.Errorf("unsupported shell: %s", args[0])
			}
		},
	}
	return cmd
}

var languageCodes = []string{
	"af", "am", "ar", "as", "az", "ba", "be", "bg", "bn", "bo", "br", "bs", "ca", "cs", "cy", "da", "de", "el", "en", "es", "et", "eu", "fa", "fi", "fo", "fr", "gl", "gu", "ha", "haw", "he", "hi", "hr", "ht", "hu", "hy", "id", "is", "it", "ja", "jw", "ka", "kk", "km", "kn", "ko", "la", "lb", "ln", "lo", "lt", "lv", "mg", "mi", "mk", "ml", "mn", "mr", "ms", "mt", "my", "ne", "nl", "nn", "no", "oc", "pa", "pl", "ps", "pt", "ro", "ru", "sa", "sd", "si", "sk", "sl", "sn", "so", "sq", "sr", "su", "sv", "sw", "ta", "te", "tg", "th", "tk", "tl", "tr", "tt", "uk", "ur", "uz", "vi", "yi", "yo", "yue", "zh",
}

var languageNames = []string{
	"Afrikaans", "Albanian", "Amharic", "Arabic", "Armenian", "Assamese", "Azerbaijani", "Bashkir", "Basque", "Belarusian", "Bengali", "Bosnian", "Breton", "Bulgarian", "Burmese", "Cantonese", "Castilian", "Catalan", "Chinese", "Croatian", "Czech", "Danish", "Dutch", "English", "Estonian", "Faroese", "Finnish", "Flemish", "French", "Galician", "Georgian", "German", "Greek", "Gujarati", "Haitian", "Haitian Creole", "Hausa", "Hawaiian", "Hebrew", "Hindi", "Hungarian", "Icelandic", "Indonesian", "Italian", "Japanese", "Javanese", "Kannada", "Kazakh", "Khmer", "Korean", "Lao", "Latin", "Latvian", "Letzeburgesch", "Lingala", "Lithuanian", "Luxembourgish", "Macedonian", "Malagasy", "Malay", "Malayalam", "Maltese", "Mandarin", "Maori", "Marathi", "Moldavian", "Moldovan", "Mongolian", "Myanmar", "Nepali", "Norwegian", "Nynorsk", "Occitan", "Panjabi", "Pashto", "Persian", "Polish", "Portuguese", "Punjabi", "Pushto", "Romanian", "Russian", "Sanskrit", "Serbian", "Shona", "Sindhi", "Sinhala", "Sinhalese", "Slovak", "Slovenian", "Somali", "Spanish", "Sundanese", "Swahili", "Swedish", "Tagalog", "Tajik", "Tamil", "Tatar", "Telugu", "Thai", "Tibetan", "Turkish", "Turkmen", "Ukrainian", "Urdu", "Uzbek", "Valencian", "Vietnamese", "Welsh", "Yiddish", "Yoruba",
}

func dirCompletion(_ *cobra.Command, _ []string, _ string) ([]string, cobra.ShellCompDirective) {
	return nil, cobra.ShellCompDirectiveFilterDirs
}
