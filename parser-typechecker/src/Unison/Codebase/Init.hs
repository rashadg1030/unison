{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE OverloadedStrings #-}

module Unison.Codebase.Init where

import qualified Data.Text as Text
import System.Exit (exitFailure)
import Unison.Codebase (Codebase, CodebasePath)
import qualified Unison.Codebase as Codebase
import Unison.Parser (Ann)
import Unison.Prelude
import qualified Unison.PrettyTerminal as PT
import Unison.Symbol (Symbol)
import qualified Unison.Util.Pretty as P
import UnliftIO.Directory (canonicalizePath)
import UnliftIO.Environment (getProgName)

type Pretty = P.Pretty P.ColorText

data CreateCodebaseError
  = CreateCodebaseAlreadyExists
  | CreateCodebaseOther Pretty

data Init m v a = Init
  { -- | open an existing codebase
    openCodebase :: CodebasePath -> m (Either Pretty (m (), Codebase m v a)),
    -- | create a new codebase
    createCodebase' :: CodebasePath -> m (Either CreateCodebaseError (m (), Codebase m v a)),
    -- | given a codebase root, and given that the codebase root may have other junk in it,
    -- give the path to the "actual" files; e.g. what a forked transcript should clone.
    codebasePath :: CodebasePath -> CodebasePath
  }

createCodebase :: MonadIO m => Init m v a -> CodebasePath -> m (Either Pretty (m (), Codebase m v a))
createCodebase cbInit path = do
  prettyDir <- P.string <$> canonicalizePath path
  createCodebase' cbInit path <&> mapLeft \case
    CreateCodebaseAlreadyExists ->
      P.wrap $
        "It looks like there's already a codebase in: "
          <> prettyDir
    CreateCodebaseOther message ->
      P.wrap ("I ran into an error when creating the codebase in: " <> prettyDir)
        <> P.newline
        <> P.newline
        <> "The error was:"
        <> P.newline
        <> P.indentN 2 message

-- * compatibility stuff

-- | load an existing codebase or exit.
getCodebaseOrExit :: MonadIO m => Init m v a -> Maybe CodebasePath -> m (m (), Codebase m v a)
getCodebaseOrExit init mdir = do
  dir <- Codebase.getCodebaseDir mdir
  openCodebase init dir >>= \case
    Left _e -> liftIO do
      progName <- getProgName
      prettyDir <- P.string <$> canonicalizePath dir
      PT.putPrettyLn' $ getNoCodebaseErrorMsg ((P.text . Text.pack) progName) prettyDir mdir
      exitFailure
    Right x -> pure x
  where
    getNoCodebaseErrorMsg :: IsString s => P.Pretty s -> P.Pretty s -> Maybe FilePath -> P.Pretty s
    getNoCodebaseErrorMsg executable prettyDir mdir =
      let secondLine =
            case mdir of
              Just dir ->
                "Run `" <> executable <> " -codebase " <> fromString dir
                  <> " init` to create one, then try again!"
              Nothing ->
                "Run `" <> executable <> " init` to create one there,"
                  <> " then try again;"
                  <> " or `"
                  <> executable
                  <> " -codebase <dir>` to load a codebase from someplace else!"
       in P.lines
            [ "No codebase exists in " <> prettyDir <> ".",
              secondLine
            ]

-- previously: initCodebaseOrExit :: CodebasePath -> m (m (), Codebase m v a)
-- previously: FileCodebase.initCodebase :: CodebasePath -> m (m (), Codebase m v a)
openNewUcmCodebaseOrExit :: MonadIO m => Init m Symbol Ann -> CodebasePath -> m (m (), Codebase m Symbol Ann)
openNewUcmCodebaseOrExit cbInit path = do
  prettyDir <- P.string <$> canonicalizePath path
  createCodebase cbInit path >>= \case
    Left error -> liftIO $ PT.putPrettyLn' error >> exitFailure
    Right x@(_, codebase) -> do
      liftIO $
        PT.putPrettyLn'
          . P.wrap
          $ "Initializing a new codebase in: "
            <> prettyDir
      Codebase.installUcmDependencies codebase
      pure x

-- | try to init a codebase where none exists and then exit regardless (i.e. `ucm -codebase dir init`)
initCodebaseAndExit :: MonadIO m => Init m Symbol Ann -> Maybe CodebasePath -> m ()
initCodebaseAndExit i mdir =
  void $ openNewUcmCodebaseOrExit i =<< Codebase.getCodebaseDir mdir
