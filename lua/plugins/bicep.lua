return {
  {
    "neovim/nvim-lspconfig",
    init = function()
      -- Tell Neovim how to classify .bicepparam files so the LSP can attach.
      vim.filetype.add({
        extension = {
          bicepparam = "bicepparam",
        },
      })

      -- Reuse the bicep treesitter grammar/syntax for .bicepparam so we keep highlighting.
      local ok, language = pcall(require, "vim.treesitter.language")
      if ok and language.register then
        language.register("bicep", "bicepparam")
      end

      local parsers_ok, parsers = pcall(require, "nvim-treesitter.parsers")
      if parsers_ok and parsers.ft_to_lang then
        parsers.ft_to_lang.bicepparam = "bicep"
      elseif parsers_ok and parsers.bicep then
        parsers.bicep.used_by = parsers.bicep.used_by or {}
        table.insert(parsers.bicep.used_by, "bicepparam")
      end

      vim.api.nvim_create_autocmd("FileType", {
        pattern = "bicepparam",
        callback = function()
          vim.bo.syntax = "bicep"
          pcall(vim.treesitter.start, 0, "bicep")
        end,
      })
    end,
    opts = function(_, opts)
      opts.servers = opts.servers or {}
      opts.servers.bicep = opts.servers.bicep or {}
      opts.servers.bicep.filetypes = { "bicep", "bicepparam" }
    end,
  },
}
