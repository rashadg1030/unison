{-# LANGUAGE DerivingVia #-}
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE StandaloneDeriving #-}
{-# OPTIONS_GHC -Wno-orphans #-}

module Unison.Server.Types where

-- Types common to endpoints --

import           Unison.Prelude
import           Data.Aeson
import qualified Data.ByteString.Lazy          as LZ
import qualified Data.Text.Lazy                as Text
import qualified Data.Text.Lazy.Encoding       as Text
import           Data.OpenApi                   ( ToSchema(..)
                                                , ToParamSchema(..)
                                                )
import           Servant.API                    ( FromHttpApiData )
import qualified Unison.HashQualified          as HQ
import           Unison.ConstructorType         ( ConstructorType )
import           Unison.Name                    ( Name )
import           Unison.ShortHash               ( ShortHash )
import           Unison.Codebase.ShortBranchHash
                                                ( ShortBranchHash(..) )
import           Unison.Util.Pretty             ( Width(..)
                                                , render
                                                )
import           Unison.Var                     ( Var )
import qualified Unison.PrettyPrintEnv         as PPE
import           Unison.Type                    ( Type )
import qualified Unison.TypePrinter            as TypePrinter
import           Unison.Codebase.Editor.DisplayObject
                                                ( DisplayObject )
import           Unison.Server.Syntax           ( SyntaxText )
import qualified Unison.Server.Syntax          as Syntax

type HashQualifiedName = Text

type Size = Int

type UnisonName = Text

type UnisonHash = Text

instance ToJSON Name where
    toEncoding = genericToEncoding defaultOptions
deriving instance ToSchema Name

deriving via Bool instance FromHttpApiData Suffixify
deriving instance ToParamSchema Suffixify

deriving via Text instance FromHttpApiData ShortBranchHash
deriving instance ToParamSchema ShortBranchHash

deriving via Int instance FromHttpApiData Width
deriving instance ToParamSchema Width

instance ToJSON a => ToJSON (DisplayObject a) where
   toEncoding = genericToEncoding defaultOptions
deriving instance ToSchema a => ToSchema (DisplayObject a)

instance ToJSON ShortHash where
   toEncoding = genericToEncoding defaultOptions
instance ToJSONKey ShortHash
deriving instance ToSchema ShortHash

instance ToJSON n => ToJSON (HQ.HashQualified n) where
   toEncoding = genericToEncoding defaultOptions
deriving instance ToSchema n => ToSchema (HQ.HashQualified n)

instance ToJSON ConstructorType where
   toEncoding = genericToEncoding defaultOptions

deriving instance ToSchema ConstructorType

instance ToJSON TypeDefinition where
   toEncoding = genericToEncoding defaultOptions

deriving instance ToSchema TypeDefinition

instance ToJSON TermDefinition where
   toEncoding = genericToEncoding defaultOptions

deriving instance ToSchema TermDefinition

instance ToJSON DefinitionDisplayResults where
   toEncoding = genericToEncoding defaultOptions

deriving instance ToSchema DefinitionDisplayResults

newtype Suffixify = Suffixify { suffixified :: Bool }
  deriving (Eq, Ord, Show, Generic)

data TermDefinition = TermDefinition
  { termNames :: [HashQualifiedName]
  , bestTermName :: HashQualifiedName
  , defnTermTag :: Maybe TermTag
  , termDefinition :: DisplayObject SyntaxText
  , signature :: SyntaxText
  } deriving (Eq, Show, Generic)

data TypeDefinition = TypeDefinition
  { typeNames :: [HashQualifiedName]
  , bestTypeName :: HashQualifiedName
  , defnTypeTag :: Maybe TypeTag
  , typeDefinition :: DisplayObject SyntaxText
  } deriving (Eq, Show, Generic)

data DefinitionDisplayResults =
  DefinitionDisplayResults
    { termDefinitions :: Map UnisonHash TermDefinition
    , typeDefinitions :: Map UnisonHash TypeDefinition
    , missingDefinitions :: [HashQualifiedName]
    } deriving (Eq, Show, Generic)

data TermTag = Doc | Test
  deriving (Eq, Ord, Show, Generic)

data TypeTag = Ability | Data
  deriving (Eq, Ord, Show, Generic)

data UnisonRef
  = TypeRef UnisonHash
  | TermRef UnisonHash
  deriving (Eq, Ord, Show, Generic)

data FoundEntry
  = FoundTerm NamedTerm
  | FoundType NamedType
  deriving (Eq, Show, Generic)

instance ToJSON FoundEntry where
  toEncoding = genericToEncoding defaultOptions

deriving instance ToSchema FoundEntry

unisonRefToText :: UnisonRef -> Text
unisonRefToText = \case
  TypeRef r -> r
  TermRef r -> r

data NamedTerm = NamedTerm
  { termName :: HashQualifiedName
  , termHash :: UnisonHash
  , termType :: Maybe SyntaxText
  , termTag :: Maybe TermTag
  }
  deriving (Eq, Generic, Show)

instance ToJSON NamedTerm where
   toEncoding = genericToEncoding defaultOptions

deriving instance ToSchema NamedTerm

data NamedType = NamedType
  { typeName :: HashQualifiedName
  , typeHash :: UnisonHash
  , typeTag :: TypeTag
  }
  deriving (Eq, Generic, Show)

instance ToJSON NamedType where
   toEncoding = genericToEncoding defaultOptions

deriving instance ToSchema NamedType

instance ToJSON TermTag where
   toEncoding = genericToEncoding defaultOptions

deriving instance ToSchema TermTag

instance ToJSON TypeTag where
   toEncoding = genericToEncoding defaultOptions

deriving instance ToSchema TypeTag

formatType :: Var v => PPE.PrettyPrintEnv -> Width -> Type v a -> SyntaxText
formatType ppe w =
  fmap Syntax.convertElement . render w . TypePrinter.pretty0 ppe mempty (-1)

munge :: Text -> LZ.ByteString
munge = Text.encodeUtf8 . Text.fromStrict

mungeShow :: Show s => s -> LZ.ByteString
mungeShow = mungeString . show

mungeString :: String -> LZ.ByteString
mungeString = Text.encodeUtf8 . Text.pack

defaultWidth :: Width
defaultWidth = 80

discard :: Applicative m => a -> m ()
discard = const $ pure ()

mayDefault :: Maybe Width -> Width
mayDefault = fromMaybe defaultWidth

