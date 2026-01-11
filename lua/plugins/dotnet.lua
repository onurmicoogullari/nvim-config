local function add_dotnet_mappings()
  local dotnet = require("easy-dotnet")

  vim.api.nvim_create_user_command("Secrets", function()
    dotnet.secrets()
  end, {})

  vim.keymap.set("n", "<leader>dt", function()
    vim.cmd("Dotnet testrunner")
  end, { silent = true, desc = "Dotnet: Run test runner" })

  vim.keymap.set("n", "<leader>dr", function()
    vim.cmd("Dotnet testrunner refresh")
  end, { silent = true, desc = "Dotnet: Refresh test runner" })

  vim.keymap.set("n", "<leader>dp", function()
    dotnet.run_with_profile(use_default)(true)
  end, { silent = true, desc = "Dotnet: Run with profile" })

  vim.keymap.set("n", "<leader>db", function()
    dotnet.build_default_quickfix()
  end, { silent = true, desc = "Dotnet: Build (Quickfix)" })
end

return {
  -- mason registry extensions
  {
    "mason-org/mason.nvim",
    opts = {
      registries = {
        "github:mason-org/mason-registry",
        "github:Crashdummyy/mason-registry",
      },
    },
  },

  -- roslyn LSP
  {
    "seblyng/roslyn.nvim",
    ft = "cs",
    config = function()
      require("roslyn").setup({
        filewatching = not vim.g.is_perf,
      })

      vim.lsp.config("roslyn", {
        settings = {
          ["csharp|background_analysis"] = {
            dotnet_compiler_diagnostics_scope = "fullSolution",
          },
          ["csharp|inlay_hints"] = {
            csharp_enable_inlay_hints_for_implicit_object_creation = true,
            csharp_enable_inlay_hints_for_implicit_variable_types = true,
            csharp_enable_inlay_hints_for_lambda_parameter_types = true,
            csharp_enable_inlay_hints_for_types = true,
          },
          ["csharp|code_lens"] = {
            dotnet_enable_references_code_lens = true,
          },
        },
      })

      local orig_progress = vim.lsp.handlers["$/progress"]

      vim.lsp.handlers["$/progress"] = function(err, result, ctx, config)
        local client = ctx and vim.lsp.get_client_by_id(ctx.client_id)
        if client and client.name == "roslyn" then
          return
        end
        if orig_progress then
          return orig_progress(err, result, ctx, config)
        end
      end

      vim.lsp.enable("roslyn")
    end,
  },

  -- easy-dotnet
  {
    "GustavEikaas/easy-dotnet.nvim",
    dependencies = { "nvim-lua/plenary.nvim", "folke/snacks.nvim" },
    config = function()
      local dotnet = require("easy-dotnet")

      dotnet.setup({
        test_runner = {
          enable_buffer_test_execution = true,
          viewmode = "float",
        },
        auto_bootstrap_namespace = {
          type = "file_scoped",
          enabled = true,
          use_clipboard_json = { behavior = "prompt", register = "+" },
        },
        picker = "snacks",
        background_scanning = true,
        terminal = function(path, action, args)
          local commands = {
            run = function()
              return string.format("dotnet run --project %s %s", path, args)
            end,
            test = function()
              return string.format("dotnet test %s %s", path, args)
            end,
            restore = function()
              return string.format("dotnet restore %s %s", path, args)
            end,
            build = function()
              return string.format("dotnet build %s %s", path, args)
            end,
          }
          require("toggleterm").exec(commands[action]() .. "\r", nil, nil, nil, "float")
        end,
      })

      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          if dotnet.is_dotnet_project() then
            add_dotnet_mappings()
          end
        end,
      })
    end,
  },

  -- C# formatter (csharpier)
  {
    "stevearc/conform.nvim",
    opts = function(_, opts)
      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters = opts.formatters or {}

      opts.formatters_by_ft.cs = { "csharpier" }

      opts.formatters.csharpier = {
        stdin = false,
        tempfile_postfix = ".cs",
        command = function()
          return vim.fn.executable("csharpier") == 1 and "csharpier" or "dotnet"
        end,
        args = function()
          if vim.fn.executable("csharpier") == 1 then
            return { "format", "$FILENAME" }
          end
          return { "tool", "run", "csharpier", "format", "$FILENAME" }
        end,
        cwd = function(_, ctx)
          return vim.fs.root(ctx.filename, {
            ".config/dotnet-tools.json",
            "dotnet-tools.json",
            ".git",
            "Directory.Build.props",
            "Directory.Build.targets",
          }) or vim.loop.cwd()
        end,
      }

      return opts
    end,
  },
}
