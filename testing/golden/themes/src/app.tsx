// Authoritative render of Radix Themes 3 — the GOLDEN source. Each component (and
// the composed Sign-in demo) renders in isolation keyed by ?c=<id>, so Playwright
// screenshots one per page; the index (no ?c=) is the human-reviewable gallery.
// This is upstream's real output — the Halogen port is pixel-diffed against it.
import React from "react";
import { createRoot } from "react-dom/client";
import "@radix-ui/themes/styles.css";
// Bare Radix primitives — Radix Themes ships NO Accordion/Collapsible/Toggle/ToggleGroup,
// so these stories compose the genuine upstream primitives directly (the DOM contract the
// Halogen port reproduces). They live in their own packages, present in node_modules.
import * as Accordion from "@radix-ui/react-accordion";
import * as Collapsible from "@radix-ui/react-collapsible";
import * as Menubar from "@radix-ui/react-menubar";
import * as NavigationMenu from "@radix-ui/react-navigation-menu";
import { Toggle } from "@radix-ui/react-toggle";
import * as ToggleGroup from "@radix-ui/react-toggle-group";
import * as Toolbar from "@radix-ui/react-toolbar";
import * as Toast from "@radix-ui/react-toast";
import * as PasswordToggleField from "@radix-ui/react-password-toggle-field";
import * as OneTimePasswordField from "@radix-ui/react-one-time-password-field";
import * as Form from "@radix-ui/react-form";
// Bare stateless primitives (Wave-B depth audit) — the genuine upstream DOM contract
// (role/aria/data-*/inline-style) the Hydrogen.Radix / Hydrogen.Themes ports reproduce.
import * as SeparatorPrim from "@radix-ui/react-separator";
import * as AspectRatioPrim from "@radix-ui/react-aspect-ratio";
import * as VisuallyHiddenPrim from "@radix-ui/react-visually-hidden";
import * as LabelPrim from "@radix-ui/react-label";
// Bundle Inter (Radix Themes' intended typeface) so the render is deterministic —
// headless Chromium has no system sans; without this the golden falls back to mono.
import "@fontsource-variable/inter";
import {
  Theme,
  Button,
  Checkbox,
  Switch,
  TextField,
  TextArea,
  Card,
  Separator,
  Badge,
  Callout,
  Avatar,
  Spinner,
  Progress,
  Code,
  Kbd,
  Quote,
  Blockquote,
  Em,
  Strong,
  Link,
  RadioGroup,
  ScrollArea,
  Slider,
  Tabs,
  Table,
  DataList,
  Flex,
  Box,
  Text,
  Heading,
  AccessibleIcon,
  AspectRatio,
  CheckboxCards,
  CheckboxGroup,
  Container,
  Grid,
  IconButton,
  Inset,
  RadioCards,
  Section,
  SegmentedControl,
  Skeleton,
  TabNav,
  VisuallyHidden,
  // Interactive (overlay) components — the open-state DOM oracle (STR-331) drives
  // these into their states and snapshots the real upstream DOM as the golden.
  Dialog,
  AlertDialog,
  Popover,
  Tooltip,
  HoverCard,
  DropdownMenu,
  ContextMenu,
  Select,
} from "@radix-ui/themes";

type Page = { id: string; label: string; node: React.ReactNode; interactive?: boolean };

const PAGES: Page[] = [
  {
    id: "button",
    label: "Button",
    node: (
      <Flex direction="column" gap="3" align="start">
        <Flex gap="3" align="center">
          <Button variant="solid">Solid</Button>
          <Button variant="soft">Soft</Button>
          <Button variant="outline">Outline</Button>
          <Button variant="surface">Surface</Button>
          <Button variant="ghost">Ghost</Button>
        </Flex>
        <Flex gap="3" align="center">
          <Button size="1">Size 1</Button>
          <Button size="2">Size 2</Button>
          <Button size="3">Size 3</Button>
          <Button disabled>Disabled</Button>
        </Flex>
      </Flex>
    ),
  },
  {
    id: "checkbox",
    label: "Checkbox",
    node: (
      <Flex direction="column" gap="2">
        <Text as="label" size="2">
          <Flex gap="2" align="center">
            <Checkbox defaultChecked /> Checked
          </Flex>
        </Text>
        <Text as="label" size="2">
          <Flex gap="2" align="center">
            <Checkbox /> Unchecked
          </Flex>
        </Text>
        <Text as="label" size="2">
          <Flex gap="2" align="center">
            <Checkbox disabled defaultChecked /> Disabled
          </Flex>
        </Text>
      </Flex>
    ),
  },
  {
    id: "switch",
    label: "Switch",
    node: (
      <Flex gap="4" align="center">
        <Switch defaultChecked />
        <Switch />
        <Switch disabled defaultChecked />
        <Switch size="1" defaultChecked />
        <Switch size="3" defaultChecked />
      </Flex>
    ),
  },
  {
    id: "textfield",
    label: "TextField",
    node: (
      <Flex direction="column" gap="3" style={{ maxWidth: 320 }}>
        <TextField.Root placeholder="Search the docs…" />
        <TextField.Root size="3" placeholder="Larger field" defaultValue="m@example.com" />
      </Flex>
    ),
  },
  {
    id: "textarea",
    label: "TextArea",
    node: (
      <Box style={{ maxWidth: 320 }}>
        <TextArea placeholder="Reply to comment…" />
      </Box>
    ),
  },
  {
    id: "badge",
    label: "Badge",
    node: (
      <Flex gap="2" align="center">
        <Badge color="green">Complete</Badge>
        <Badge color="orange">In progress</Badge>
        <Badge color="red">Failed</Badge>
        <Badge variant="solid">Solid</Badge>
      </Flex>
    ),
  },
  {
    id: "callout",
    label: "Callout",
    node: (
      <Box style={{ maxWidth: 420 }}>
        <Callout.Root>
          <Callout.Text>
            You will need admin privileges to install and access this application.
          </Callout.Text>
        </Callout.Root>
      </Box>
    ),
  },
  {
    id: "card",
    label: "Card",
    node: (
      <Box style={{ maxWidth: 320 }}>
        <Card>
          <Flex gap="3" align="center">
            <Box>
              <Text as="div" size="2" weight="bold">
                Teodros Girmay
              </Text>
              <Text as="div" size="2" color="gray">
                Engineering
              </Text>
            </Box>
          </Flex>
        </Card>
      </Box>
    ),
  },
  {
    id: "avatar",
    label: "Avatar",
    node: (
      <Flex gap="3" align="center">
        <Avatar fallback="A" />
        <Avatar fallback="TG" color="indigo" />
        <Avatar fallback="RT" variant="solid" />
        <Avatar size="5" fallback="L" />
      </Flex>
    ),
  },
  {
    id: "spinner",
    label: "Spinner",
    node: (
      <Flex gap="4" align="center">
        <Spinner size="1" />
        <Spinner size="2" />
        <Spinner size="3" />
      </Flex>
    ),
  },
  {
    id: "progress",
    label: "Progress",
    node: (
      <Flex direction="column" gap="4" style={{ maxWidth: 320 }}>
        <Progress value={25} />
        <Progress value={60} color="cyan" />
        <Progress value={90} variant="soft" />
      </Flex>
    ),
  },
  {
    id: "separator",
    label: "Separator",
    node: (
      <Flex direction="column" gap="3" style={{ maxWidth: 240 }}>
        <Text size="2">Above</Text>
        <Separator size="4" />
        <Text size="2">Below</Text>
      </Flex>
    ),
  },
  {
    id: "code",
    label: "Code",
    node: (
      <Text size="3">
        Run <Code>npm install</Code> then <Code variant="solid">npm start</Code>.
      </Text>
    ),
  },
  {
    id: "kbd",
    label: "Kbd",
    node: (
      <Text size="3">
        Press <Kbd>Shift + Tab</Kbd> to go back.
      </Text>
    ),
  },
  {
    id: "quote",
    label: "Quote",
    node: (
      <Text size="3">
        <Quote>Design is not just what it looks like and feels like.</Quote>
      </Text>
    ),
  },
  {
    id: "blockquote",
    label: "Blockquote",
    node: (
      <Box style={{ maxWidth: 360 }}>
        <Blockquote>
          Perfect is the enemy of good. Ship the thing, then make it better.
        </Blockquote>
      </Box>
    ),
  },
  {
    id: "emstrong",
    label: "Em / Strong",
    node: (
      <Text size="3">
        The <Strong>quick</Strong> brown fox is <Em>remarkably</Em> fast.
      </Text>
    ),
  },
  {
    id: "link",
    label: "Link",
    node: (
      <Text size="3">
        Read the <Link href="#">documentation</Link> for more.
      </Text>
    ),
  },
  {
    id: "radiogroup",
    label: "RadioGroup",
    node: (
      <RadioGroup.Root defaultValue="1">
        <Flex direction="column" gap="2">
          <Text as="label" size="2">
            <Flex gap="2" align="center">
              <RadioGroup.Item value="1" /> Default
            </Flex>
          </Text>
          <Text as="label" size="2">
            <Flex gap="2" align="center">
              <RadioGroup.Item value="2" /> Comfortable
            </Flex>
          </Text>
          <Text as="label" size="2">
            <Flex gap="2" align="center">
              <RadioGroup.Item value="3" /> Compact
            </Flex>
          </Text>
        </Flex>
      </RadioGroup.Root>
    ),
  },
  {
    id: "slider",
    label: "Slider",
    node: (
      <Box style={{ maxWidth: 320 }}>
        <Slider defaultValue={[40]} />
      </Box>
    ),
  },
  {
    id: "tabs",
    label: "Tabs",
    node: (
      <Tabs.Root defaultValue="account">
        <Tabs.List>
          <Tabs.Trigger value="account">Account</Tabs.Trigger>
          <Tabs.Trigger value="documents">Documents</Tabs.Trigger>
          <Tabs.Trigger value="settings">Settings</Tabs.Trigger>
        </Tabs.List>
      </Tabs.Root>
    ),
  },
  {
    id: "table",
    label: "Table",
    node: (
      <Box style={{ maxWidth: 480 }}>
        <Table.Root>
          <Table.Header>
            <Table.Row>
              <Table.ColumnHeaderCell>Name</Table.ColumnHeaderCell>
              <Table.ColumnHeaderCell>Email</Table.ColumnHeaderCell>
            </Table.Row>
          </Table.Header>
          <Table.Body>
            <Table.Row>
              <Table.RowHeaderCell>Danilo</Table.RowHeaderCell>
              <Table.Cell>danilo@example.com</Table.Cell>
            </Table.Row>
            <Table.Row>
              <Table.RowHeaderCell>Zahra</Table.RowHeaderCell>
              <Table.Cell>zahra@example.com</Table.Cell>
            </Table.Row>
          </Table.Body>
        </Table.Root>
      </Box>
    ),
  },
  {
    id: "datalist",
    label: "DataList",
    node: (
      <DataList.Root>
        <DataList.Item>
          <DataList.Label>Status</DataList.Label>
          <DataList.Value>
            <Badge color="jade">Authorized</Badge>
          </DataList.Value>
        </DataList.Item>
        <DataList.Item>
          <DataList.Label>Name</DataList.Label>
          <DataList.Value>Vlad Moroz</DataList.Value>
        </DataList.Item>
      </DataList.Root>
    ),
  },
  {
    id: "container",
    label: "Container",
    node: (
      <Container size="1">
        <Box p="4" style={{ border: '1px solid var(--gray-6)' }} className="rt-reset" data-radius="3">
          <Text>Centered, max-width container content.</Text>
        </Box>
      </Container>
    ),
  },
  {
    id: "grid",
    label: "Grid",
    node: (
      <Grid columns="3" gap="3">
        <Box height="64px" style={{ backgroundColor: 'var(--accent-9)' }} />
        <Box height="64px" style={{ backgroundColor: 'var(--accent-9)' }} />
        <Box height="64px" style={{ backgroundColor: 'var(--accent-9)' }} />
        <Box height="64px" style={{ backgroundColor: 'var(--accent-9)' }} />
        <Box height="64px" style={{ backgroundColor: 'var(--accent-9)' }} />
        <Box height="64px" style={{ backgroundColor: 'var(--accent-9)' }} />
      </Grid>
    ),
  },
  {
    id: "section",
    label: "Section",
    node: (
      <Box style={{ border: '1px solid #ccc', maxWidth: '400px' }}>
        <Section>
          <Text size="3">Section content with default vertical padding.</Text>
        </Section>
      </Box>
    ),
  },
  {
    id: "inset",
    label: "Inset",
    node: (
      <Card>
        <Inset side="top" pb="current">
          <Box style={{ backgroundColor: "var(--gray-5)", height: "120px" }} />
        </Inset>
        <Text size="2">
          Typography is the art and technique of arranging type to make written language legible, readable and appealing when displayed.
        </Text>
      </Card>
    ),
  },
  {
    id: "aspectratio",
    label: "Aspect Ratio",
    node: (
      <Box width="300px">
        <AspectRatio ratio={16 / 9}>
          <Box
            style={{
              width: "100%",
              height: "100%",
              backgroundColor: "var(--indigo-9)",
            }}
          />
        </AspectRatio>
      </Box>
    ),
  },
  {
    id: "iconbutton",
    label: "Icon Button",
    node: (
      <Flex gap="3" align="center">
        {(() => {
          const GearIcon = (
            <svg
              className="rt-IconButtonIcon"
              width="16"
              height="16"
              viewBox="0 0 16 16"
              fill="currentColor"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                fillRule="evenodd"
                clipRule="evenodd"
                d="M5.879.673a.5.5 0 0 1 .49-.402h1.262a.5.5 0 0 1 .49.402l.27 1.353a5.5 5.5 0 0 1 1.31.755l1.31-.45a.5.5 0 0 1 .596.21l.63 1.092a.5.5 0 0 1-.105.625l-1.04.902a5.6 5.6 0 0 1 0 1.51l1.04.902a.5.5 0 0 1 .106.625l-.631 1.093a.5.5 0 0 1-.596.21l-1.31-.451a5.5 5.5 0 0 1-1.31.755l-.27 1.353a.5.5 0 0 1-.49.402H6.369a.5.5 0 0 1-.49-.402l-.27-1.353a5.5 5.5 0 0 1-1.31-.755l-1.31.451a.5.5 0 0 1-.596-.21l-.631-1.093a.5.5 0 0 1 .106-.625l1.04-.902a5.6 5.6 0 0 1 0-1.51l-1.04-.902a.5.5 0 0 1-.106-.625l.631-1.093a.5.5 0 0 1 .596-.21l1.31.451a5.5 5.5 0 0 1 1.31-.755zM7 10a3 3 0 1 0 0-6 3 3 0 0 0 0 6"
              />
            </svg>
          );
          return (
            <>
              <IconButton variant="solid">{GearIcon}</IconButton>
              <IconButton variant="soft">{GearIcon}</IconButton>
              <IconButton variant="outline">{GearIcon}</IconButton>
              <IconButton variant="ghost">{GearIcon}</IconButton>
            </>
          );
        })()}
      </Flex>
    ),
  },
  {
    id: "skeleton",
    label: "Skeleton",
    node: (
      <Box style={{ maxWidth: 320 }}>
        <Text as="p" size="3"><Skeleton>Lorem ipsum dolor sit amet, consectetur.</Skeleton></Text>
        <Text as="p" size="3"><Skeleton>Adipiscing elit sed do eiusmod tempor.</Skeleton></Text>
        <Text as="p" size="3"><Skeleton>Incididunt ut labore et dolore.</Skeleton></Text>
        <Box mt="3">
          <Skeleton style={{ width: 48, height: 48, borderRadius: '100%' }} />
        </Box>
      </Box>
    ),
  },
  {
    id: "visuallyhidden",
    label: "Visually Hidden",
    node: (
      <label>
        Email
        <VisuallyHidden> (required)</VisuallyHidden>
      </label>
    ),
  },
  {
    id: "accessibleicon",
    label: "Accessible Icon",
    node: (
      <Flex align="center">
        <AccessibleIcon label="Settings">
          <svg
            width="15"
            height="15"
            viewBox="0 0 15 15"
            fill="none"
            xmlns="http://www.w3.org/2000/svg"
          >
            <path
              fillRule="evenodd"
              clipRule="evenodd"
              fill="currentColor"
              d="M7.07.65a1.5 1.5 0 0 0-1.14 0l-.69.29-.74-.18a1.5 1.5 0 0 0-1.07.2l-.6.43-.76.05a1.5 1.5 0 0 0-.98.55l-.42.6-.7.3a1.5 1.5 0 0 0-.78.78l-.3.7-.43.6a1.5 1.5 0 0 0-.2 1.07l.18.74-.29.69a1.5 1.5 0 0 0 0 1.14l.29.69-.18.74a1.5 1.5 0 0 0 .2 1.07l.43.6.3.7c.16.36.43.63.78.78l.7.3.42.6c.24.34.6.55.98.55l.76.05.6.43c.32.23.7.3 1.07.2l.74-.18.69.29c.36.15.78.15 1.14 0l.69-.29.74.18c.37.1.75.03 1.07-.2l.6-.43.76-.05c.38 0 .74-.21.98-.55l.42-.6.7-.3a1.5 1.5 0 0 0 .78-.78l.3-.7.43-.6c.23-.32.3-.7.2-1.07l-.18-.74.29-.69a1.5 1.5 0 0 0 0-1.14l-.29-.69.18-.74a1.5 1.5 0 0 0-.2-1.07l-.43-.6-.3-.7a1.5 1.5 0 0 0-.78-.78l-.7-.3-.42-.6a1.5 1.5 0 0 0-.98-.55l-.76-.05-.6-.43a1.5 1.5 0 0 0-1.07-.2l-.74.18L7.07.65ZM7.5 10a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5Z"
            />
          </svg>
        </AccessibleIcon>
      </Flex>
    ),
  },
  {
    id: "tabnav",
    label: "Tab Nav",
    node: (
      <TabNav.Root>
        <TabNav.Link href="#account" active>
          Account
        </TabNav.Link>
        <TabNav.Link href="#documents">Documents</TabNav.Link>
        <TabNav.Link href="#settings">Settings</TabNav.Link>
      </TabNav.Root>
    ),
  },
  {
    id: "segmentedcontrol",
    label: "Segmented Control",
    node: (
      <SegmentedControl.Root defaultValue="inbox">
        <SegmentedControl.Item value="inbox">Inbox</SegmentedControl.Item>
        <SegmentedControl.Item value="drafts">Drafts</SegmentedControl.Item>
        <SegmentedControl.Item value="sent">Sent</SegmentedControl.Item>
      </SegmentedControl.Root>
    ),
  },
  {
    id: "checkboxgroup",
    label: "Checkbox Group",
    node: (
      <CheckboxGroup.Root defaultValue={["1"]}>
        <CheckboxGroup.Item value="1">Fun</CheckboxGroup.Item>
        <CheckboxGroup.Item value="2">Serious</CheckboxGroup.Item>
        <CheckboxGroup.Item value="3">Smart</CheckboxGroup.Item>
      </CheckboxGroup.Root>
    ),
  },
  {
    id: "checkboxcards",
    label: "Checkbox Cards",
    node: (
      <CheckboxCards.Root defaultValue={['terms']}>
        <CheckboxCards.Item value="terms">
          <Text>Agree to Terms and Conditions</Text>
        </CheckboxCards.Item>
        <CheckboxCards.Item value="newsletter">
          <Text>Subscribe to newsletter</Text>
        </CheckboxCards.Item>
      </CheckboxCards.Root>
    ),
  },
  {
    id: "radiocards",
    label: "Radio Cards",
    node: (
      <RadioCards.Root defaultValue="1">
        <RadioCards.Item value="1">
          <Text weight="bold">8-core CPU</Text>
        </RadioCards.Item>
        <RadioCards.Item value="2">
          <Text weight="bold">6-core CPU</Text>
        </RadioCards.Item>
        <RadioCards.Item value="3">
          <Text weight="bold">4-core CPU</Text>
        </RadioCards.Item>
      </RadioCards.Root>
    ),
  },
  // ── Interactive (overlay) components ────────────────────────────────────────
  // Rendered closed; the open-state DOM oracle (themes-open-dom.mjs) drives each
  // into its states and snapshots the real upstream DOM. Content is fixed/canonical
  // so the normalized snapshot is deterministic.
  {
    id: "dialog",
    label: "Dialog",
    node: (
      <Dialog.Root>
        <Dialog.Trigger>
          <Button>Edit profile</Button>
        </Dialog.Trigger>
        <Dialog.Content maxWidth="450px">
          <Dialog.Title>Edit profile</Dialog.Title>
          <Dialog.Description size="2" mb="4">
            Make changes to your profile.
          </Dialog.Description>
          <Flex direction="column" gap="3">
            <label>
              <Text as="div" size="2" mb="1" weight="bold">
                Name
              </Text>
              <TextField.Root defaultValue="Freja Johnsen" placeholder="Enter your full name" />
            </label>
          </Flex>
          <Flex gap="3" mt="4" justify="end">
            <Dialog.Close>
              <Button variant="soft" color="gray">
                Cancel
              </Button>
            </Dialog.Close>
            <Dialog.Close>
              <Button>Save</Button>
            </Dialog.Close>
          </Flex>
        </Dialog.Content>
      </Dialog.Root>
    ),
  },
  {
    id: "alertdialog",
    label: "Alert Dialog",
    node: (
      <AlertDialog.Root>
        <AlertDialog.Trigger>
          <Button color="red">Revoke access</Button>
        </AlertDialog.Trigger>
        <AlertDialog.Content maxWidth="450px">
          <AlertDialog.Title>Revoke access</AlertDialog.Title>
          <AlertDialog.Description size="2">
            Are you sure? This application will no longer be accessible.
          </AlertDialog.Description>
          <Flex gap="3" mt="4" justify="end">
            <AlertDialog.Cancel>
              <Button variant="soft" color="gray">
                Cancel
              </Button>
            </AlertDialog.Cancel>
            <AlertDialog.Action>
              <Button color="red">Revoke access</Button>
            </AlertDialog.Action>
          </Flex>
        </AlertDialog.Content>
      </AlertDialog.Root>
    ),
  },
  {
    id: "popover",
    label: "Popover",
    node: (
      <Popover.Root>
        <Popover.Trigger>
          <Button variant="soft">Comment</Button>
        </Popover.Trigger>
        <Popover.Content width="360px">
          <Flex gap="3">
            <Box flexGrow="1">
              <TextArea placeholder="Write a comment…" style={{ height: 80 }} />
            </Box>
          </Flex>
        </Popover.Content>
      </Popover.Root>
    ),
  },
  {
    id: "tooltip",
    label: "Tooltip",
    node: (
      <Tooltip content="Add to library">
        <Button variant="soft">Hover me</Button>
      </Tooltip>
    ),
  },
  {
    id: "hovercard",
    label: "Hover Card",
    interactive: true,
    // ?s=richcontent → the card content holds a tabbable <a>; upstream's open effect walks
    // getTabbableNodes(content) and sets tabindex=-1 on each (a hover-card is a PREVIEW, not a
    // focus target). Every other path renders the plain prose content (the original story), so
    // the open/rest oracles are unchanged.
    node: (() => {
      const rich = currentState() === "richcontent";
      return (
        <Text>
          Follow{" "}
          <HoverCard.Root>
            <HoverCard.Trigger>
              <Link href="#">@radix_ui</Link>
            </HoverCard.Trigger>
            <HoverCard.Content maxWidth="300px">
              {rich ? (
                <Text as="div" size="1" color="gray">
                  See the <Link href="https://radix-ui.com">docs</Link> for details.
                </Text>
              ) : (
                <Text as="div" size="1" color="gray">
                  The design system for building modern web applications.
                </Text>
              )}
            </HoverCard.Content>
          </HoverCard.Root>{" "}
          for updates.
        </Text>
      );
    })(),
  },
  {
    id: "dropdownmenu",
    label: "Dropdown Menu",
    // `?s=disabled` disables the SECOND item (Duplicate) so the APG disabled-skip check
    // proves roving navigation + click skip it (menu.tsx:540 filter(!disabled), :720
    // focusable={!disabled}, :639 select guard). Every other path renders all enabled.
    node: (() => {
      const dupDisabled = currentState() === "disabled";
      return (
        <DropdownMenu.Root>
          <DropdownMenu.Trigger>
            <Button variant="soft">
              Options
              <DropdownMenu.TriggerIcon />
            </Button>
          </DropdownMenu.Trigger>
          <DropdownMenu.Content>
            <DropdownMenu.Item shortcut="⌘ E">Edit</DropdownMenu.Item>
            <DropdownMenu.Item shortcut="⌘ D" disabled={dupDisabled}>Duplicate</DropdownMenu.Item>
            <DropdownMenu.Separator />
            <DropdownMenu.Item shortcut="⌘ N">Archive</DropdownMenu.Item>
            <DropdownMenu.Separator />
            <DropdownMenu.Item shortcut="⌘ ⌫" color="red">
              Delete
            </DropdownMenu.Item>
          </DropdownMenu.Content>
        </DropdownMenu.Root>
      );
    })(),
  },
  {
    id: "contextmenu",
    label: "Context Menu",
    // `?s=disabled` disables the SECOND item (Duplicate) so the APG disabled-skip check
    // proves roving navigation skips it (menu.tsx:540 filter(!disabled), :720
    // focusable={!disabled}). Every other state renders all enabled.
    node: (() => {
      const dupDisabled = currentState() === "disabled";
      return (
        <ContextMenu.Root>
          <ContextMenu.Trigger>
            <Flex
              align="center"
              justify="center"
              style={{
                width: 240,
                height: 120,
                border: "1px dashed var(--gray-6)",
                borderRadius: "var(--radius-3)",
              }}
            >
              <Text size="2" color="gray">
                Right-click here
              </Text>
            </Flex>
          </ContextMenu.Trigger>
          <ContextMenu.Content>
            <ContextMenu.Item shortcut="⌘ E">Edit</ContextMenu.Item>
            <ContextMenu.Item shortcut="⌘ D" disabled={dupDisabled}>Duplicate</ContextMenu.Item>
            <ContextMenu.Separator />
            <ContextMenu.Item shortcut="⌘ ⌫" color="red">
              Delete
            </ContextMenu.Item>
          </ContextMenu.Content>
        </ContextMenu.Root>
      );
    })(),
  },
  {
    id: "select",
    label: "Select",
    node: (
      <Select.Root defaultValue="apple">
        <Select.Trigger />
        <Select.Content>
          <Select.Group>
            <Select.Label>Fruits</Select.Label>
            <Select.Item value="apple">Apple</Select.Item>
            <Select.Item value="orange">Orange</Select.Item>
            <Select.Item value="grape">Grape</Select.Item>
          </Select.Group>
        </Select.Content>
      </Select.Root>
    ),
  },
  // ── Interactive (stateful, non-overlay) components — open-state DOM oracle ──────
  // Driven into a post-interaction state (checked / active / pressed / open / selected)
  // by themes-open-dom.mjs and snapshotted as the golden. Flagged `interactive` so the
  // open-state path (?c=<id>&s=<state>) selects THESE pages while the at-rest pixel path
  // (?c=<id>) keeps hitting the canonical at-rest pages above (PNG oracles untouched).
  // For the four primitives Radix Themes ships NO component (Accordion/Collapsible/Toggle/
  // ToggleGroup) these are the genuine bare @radix-ui/react-* upstream — the port's contract.
  {
    id: "accordion",
    label: "Accordion",
    interactive: true,
    node: (() => {
      // `?s=disabled` disables the MIDDLE trigger (item-2) so the APG disabled-skip
      // check can prove arrows skip OVER it (accordion.tsx:236 filters disabled out of
      // the navigable collection). Every other state renders all three enabled.
      const s = currentState();
      const disableMiddle = s === "disabled";
      const items = [
        { value: "item-1", header: "Is it accessible?", content: "Yes. It adheres to the WAI-ARIA design pattern.", disabled: false },
        { value: "item-2", header: "Is it styled?", content: "No. It is unstyled by default.", disabled: disableMiddle },
        { value: "item-3", header: "Is it animated?", content: "Yes, with CSS.", disabled: false },
      ];
      // `?s=single` renders type="single" (NON-collapsible) with item-1 open at first paint:
      // the open trigger CANNOT be closed, so upstream stamps aria-disabled=true on it
      // (accordion.tsx:452). Every other state keeps the default type="multiple".
      const rootProps =
        s === "single"
          ? ({ type: "single", defaultValue: "item-1" } as const)
          : ({ type: "multiple" } as const);
      return (
        <Box style={{ maxWidth: 360 }}>
          <Accordion.Root {...rootProps}>
            {items.map((it) => (
              <Accordion.Item key={it.value} value={it.value}>
                <Accordion.Header>
                  <Accordion.Trigger disabled={it.disabled}>{it.header}</Accordion.Trigger>
                </Accordion.Header>
                <Accordion.Content>{it.content}</Accordion.Content>
              </Accordion.Item>
            ))}
          </Accordion.Root>
        </Box>
      );
    })(),
  },
  {
    id: "collapsible",
    label: "Collapsible",
    interactive: true,
    // `?s=disabled` stamps `disabled` on the Root (→ data-disabled="" on root+trigger+content,
    // the trigger's `disabled` attr, and a non-interactive trigger). The default (open/rest)
    // story is the plain enabled disclosure. The injected exit keyframe on the CLOSING content
    // (data-state="closed") makes Presence keep the content MOUNTED through the pinned (100s)
    // exit — the lingering closing node the closing-DOM oracle captures (otherwise the bare,
    // unstyled content has animation-name:none and unmounts synchronously, like menubar).
    node: (() => {
      const disabled = currentState() === "disabled";
      return (
        <>
          <style>{`@keyframes collapsibleExit { from { opacity: 1 } to { opacity: 0 } }
            div[data-state="closed"][id] { animation: collapsibleExit 100ms ease-out; }`}</style>
          <Collapsible.Root disabled={disabled}>
            <Collapsible.Trigger asChild>
              <Button variant="soft">Toggle content</Button>
            </Collapsible.Trigger>
            <Collapsible.Content>
              <Box pt="2">
                <Text as="div" size="2">Disclosed content line one.</Text>
              </Box>
            </Collapsible.Content>
          </Collapsible.Root>
        </>
      );
    })(),
  },
  {
    id: "toast",
    label: "Toast",
    interactive: true,
    // Bare @radix-ui/react-toast (Radix Themes ships none) — NO rt-* classes; the genuine
    // upstream primitive. Toast is TIME-DRIVEN (auto-dismiss + swipe + queue), so the whole
    // determinism game is to defuse the clock: render ONE toast CONTROLLED open={true} with
    // duration={Infinity} AND a huge Provider duration, so the auto-dismiss timer NEVER fires
    // inside the capture window and the open state is stable at first paint (no trigger click,
    // no queue timing). swipeDirection="right" pins data-swipe-direction.
    //
    // UNCONTROLLED, not open={true}: the Root takes NO `open` prop, so it falls to defaultOpen=
    // true (it is mounted open at first paint — identical open oracle) BUT the internal open
    // state remains LIVE, so Escape → onClose → setOpen(false) actually flips it (a controlled
    // open={true} would re-pin open=true and suppress the close, making the closing oracle
    // impossible). duration={Infinity} kills the auto-dismiss timer either way, so uncontrolled
    // is still race-free for the OPEN snapshot. The story injects a minimal exit keyframe on
    // li[data-state="closed"] so the CLOSING lifecycle is real and capturable (Presence keeps
    // the li mounted through the exit animation, then unmounts) — otherwise unstyled toast would
    // unmount synchronously like select/tooltip and there would be no closing node to oracle.
    node: (
      <>
        <style>{`@keyframes toastExit { from { opacity: 1 } to { opacity: 0 } }
          li[data-state="closed"][data-swipe-direction] { animation: toastExit 100ms ease-out; }`}</style>
        <Toast.Provider duration={1000000} swipeDirection="right">
          <Toast.Root duration={Infinity}>
            <Toast.Title>Scheduled</Toast.Title>
            <Toast.Description>Friday at 5pm</Toast.Description>
            <Toast.Action altText="Undo">Undo</Toast.Action>
            <Toast.Close aria-label="Close">×</Toast.Close>
          </Toast.Root>
          <Toast.Viewport />
        </Toast.Provider>
      </>
    ),
  },
  {
    id: "menubar",
    label: "Menubar",
    interactive: true,
    // Bare @radix-ui/react-menubar (Radix Themes ships none) — NO rt-* classes; the genuine
    // upstream primitive. A horizontal roving bar of DropdownMenu-style menus. Each
    // MenubarMenu is non-modal (no scroll-lock/hideOthers), but DOES use the Popper + Presence
    // + roving. The driver opens the first menu (File) and (for item1) ArrowDowns to highlight
    // the first item. Fixed labels, no checkbox/radio/sub in v1.
    // `?s=disabled` disables "New Window" (item-2 of File) so the APG disabled-skip check
    // proves vertical roving skips it (react-menu filter(!disabled)); every other state
    // renders all enabled.
    node: (() => {
      const newWindowDisabled = currentState() === "disabled";
      return (
      <Menubar.Root>
        <Menubar.Menu value="file">
          <Menubar.Trigger>File</Menubar.Trigger>
          <Menubar.Portal>
            <Menubar.Content align="start">
              <Menubar.Item>New Tab</Menubar.Item>
              <Menubar.Item disabled={newWindowDisabled}>New Window</Menubar.Item>
              <Menubar.Separator />
              <Menubar.Item>Print</Menubar.Item>
            </Menubar.Content>
          </Menubar.Portal>
        </Menubar.Menu>
        <Menubar.Menu value="edit">
          <Menubar.Trigger>Edit</Menubar.Trigger>
          <Menubar.Portal>
            <Menubar.Content align="start">
              <Menubar.Item>Undo</Menubar.Item>
              <Menubar.Item>Redo</Menubar.Item>
            </Menubar.Content>
          </Menubar.Portal>
        </Menubar.Menu>
        <Menubar.Menu value="view">
          <Menubar.Trigger>View</Menubar.Trigger>
          <Menubar.Portal>
            <Menubar.Content align="start">
              <Menubar.Item>Zoom In</Menubar.Item>
              <Menubar.Item>Zoom Out</Menubar.Item>
            </Menubar.Content>
          </Menubar.Portal>
        </Menubar.Menu>
      </Menubar.Root>
      );
    })(),
  },
  {
    id: "navigationmenu",
    label: "Navigation Menu",
    interactive: true,
    // Bare @radix-ui/react-navigation-menu (Radix Themes ships none) — NO rt-* classes; the
    // genuine upstream primitive. A horizontal nav with ONE item (value="one"): Trigger
    // "Item One" + Content (two Links). DETERMINISM: the `open` story sets defaultValue="one"
    // so the panel is OPEN at first paint — sidestepping the delayDuration/skipDelayDuration
    // open timers entirely (no hover, no waitForTimeout race). The `closed` variant (?s=closed)
    // omits defaultValue → at rest. Viewport mode (the default): Content is proxied INTO the
    // Viewport (a sibling of List under Root), which measures the active content and sets the
    // --radix-navigation-menu-viewport-width/height vars; the Indicator (inside the List's
    // relative track) measures the active trigger's offset and renders translateX(offset)/width.
    node: (() => {
      // Render OPEN only for the explicit `open` capture state (defaultValue="one" → open at
      // first paint, no timer). Every other path (the `closed`/`rest` capture, the index
      // gallery) renders at rest, so the a11y `rest` baseline is the genuine closed nav.
      const open = currentState() === "open" || currentState() === "clicktoggle";
      // Wave-B depth: ?s=vertical → an OPEN vertical-orientation nav (data-orientation=vertical,
      // the Indicator measures top/height/translateY instead of left/width/translateX). ?s=open
      // and ?s=vertical both open Item One at first paint via defaultValue.
      const vertical = currentState() === "vertical";
      return (
        <NavigationMenu.Root
          {...(open || vertical ? { defaultValue: "one" } : {})}
          {...(vertical ? { orientation: "vertical" as const } : {})}
        >
          <NavigationMenu.List>
            <NavigationMenu.Item value="one">
              <NavigationMenu.Trigger>Item One</NavigationMenu.Trigger>
              <NavigationMenu.Content>
                <NavigationMenu.Link href="#one">Content One</NavigationMenu.Link>
                <NavigationMenu.Link href="#two">Content Two</NavigationMenu.Link>
              </NavigationMenu.Content>
            </NavigationMenu.Item>
            <NavigationMenu.Item value="two">
              <NavigationMenu.Trigger>Item Two</NavigationMenu.Trigger>
              <NavigationMenu.Content>
                <NavigationMenu.Link href="#three">Content Three</NavigationMenu.Link>
              </NavigationMenu.Content>
            </NavigationMenu.Item>
            <NavigationMenu.Indicator />
          </NavigationMenu.List>
          <NavigationMenu.Viewport />
        </NavigationMenu.Root>
      );
    })(),
  },
  {
    id: "tabs",
    label: "Tabs (interactive)",
    interactive: true,
    // `?s=disabled-skip` disables the MIDDLE tab (Documents) so the APG roving check proves
    // ArrowRight skips OVER it (RovingFocusGroup.Item focusable={!disabled}). Keyboard-only
    // (no new DOM golden — the themed rt-Tabs class contract is pinned by tab2). Every other
    // state keeps the 3-enabled instance.
    node: (
      <Tabs.Root defaultValue="account">
        <Tabs.List>
          <Tabs.Trigger value="account">Account</Tabs.Trigger>
          <Tabs.Trigger value="documents" disabled={currentState() === "disabled-skip"}>Documents</Tabs.Trigger>
          <Tabs.Trigger value="settings">Settings</Tabs.Trigger>
        </Tabs.List>
        <Tabs.Content value="account">
          <Text size="2">Make changes to your account.</Text>
        </Tabs.Content>
        <Tabs.Content value="documents">
          <Text size="2">Access and update your documents.</Text>
        </Tabs.Content>
        <Tabs.Content value="settings">
          <Text size="2">Edit your profile or update contact information.</Text>
        </Tabs.Content>
      </Tabs.Root>
    ),
  },
  {
    id: "radiogroup",
    label: "RadioGroup (interactive)",
    interactive: true,
    // Default: 2 items (the committed `checked` driver clicks value=2). `?s=keys` seeds a
    // 3-item group with the MIDDLE item disabled — the canonical fixture for disabled-skip
    // roving, Enter-no-activate, Home/End-no-check, and a real first→last wrap.
    node: (() => {
      const s = currentState();
      // `?s=keys` / `?s=mixed` — 3 items, middle disabled (roving-skip + mixed-render fixture).
      if (s === "keys" || s === "mixed") {
        return (
          <RadioGroup.Root defaultValue="1">
            <Flex direction="column" gap="2">
              <Text as="label" size="2">
                <Flex gap="2" align="center">
                  <RadioGroup.Item value="1" /> Default
                </Flex>
              </Text>
              <Text as="label" size="2">
                <Flex gap="2" align="center">
                  <RadioGroup.Item value="2" disabled /> Comfortable
                </Flex>
              </Text>
              <Text as="label" size="2">
                <Flex gap="2" align="center">
                  <RadioGroup.Item value="3" /> Compact
                </Flex>
              </Text>
            </Flex>
          </RadioGroup.Root>
        );
      }
      // `?s=disabledgroup` — the whole group disabled (root + every item data-disabled='').
      if (s === "disabledgroup") {
        return (
          <RadioGroup.Root defaultValue="1" disabled>
            <Flex direction="column" gap="2">
              <Text as="label" size="2">
                <Flex gap="2" align="center">
                  <RadioGroup.Item value="1" /> Default
                </Flex>
              </Text>
              <Text as="label" size="2">
                <Flex gap="2" align="center">
                  <RadioGroup.Item value="2" /> Comfortable
                </Flex>
              </Text>
            </Flex>
          </RadioGroup.Root>
        );
      }
      // `?s=horizontal` — explicit horizontal orientation (aria-orientation/data-orientation).
      if (s === "horizontal") {
        return (
          <RadioGroup.Root defaultValue="1" orientation="horizontal">
            <Flex direction="column" gap="2">
              <Text as="label" size="2">
                <Flex gap="2" align="center">
                  <RadioGroup.Item value="1" /> Default
                </Flex>
              </Text>
              <Text as="label" size="2">
                <Flex gap="2" align="center">
                  <RadioGroup.Item value="2" /> Comfortable
                </Flex>
              </Text>
            </Flex>
          </RadioGroup.Root>
        );
      }
      return (
        <RadioGroup.Root defaultValue="1">
          <Flex direction="column" gap="2">
            <Text as="label" size="2">
              <Flex gap="2" align="center">
                <RadioGroup.Item value="1" /> Default
              </Flex>
            </Text>
            <Text as="label" size="2">
              <Flex gap="2" align="center">
                <RadioGroup.Item value="2" /> Comfortable
              </Flex>
            </Text>
          </Flex>
        </RadioGroup.Root>
      );
    })(),
  },
  {
    id: "checkbox",
    label: "Checkbox (interactive)",
    interactive: true,
    // default = bare unchecked (the `checked` driver clicks to check). `?s=indeterminate`
    // seeds the mixed state (aria-checked=mixed, indicator shown); `?s=disabled` the no-op
    // disabled render (data-disabled='' on root AND indicator).
    node: (() => {
      const s = currentState();
      if (s === "indeterminate") return <Checkbox defaultChecked="indeterminate" />;
      if (s === "disabled") return <Checkbox disabled defaultChecked />;
      return <Checkbox />;
    })(),
  },
  {
    id: "switch",
    label: "Switch (interactive)",
    interactive: true,
    // default = OFF (the `on` driver clicks to turn on; `rest` captures off). `?s=disabled`
    // seeds the disabled no-op render (data-disabled='' on root + thumb); `?s=required`
    // documents the aria-required=true surface.
    node: (() => {
      const s = currentState();
      if (s === "disabled") return <Switch disabled />;
      if (s === "required") return <Switch required />;
      return <Switch />;
    })(),
  },
  {
    id: "toggle",
    label: "Toggle",
    interactive: true,
    // `?s=disabled` seeds a disabled toggle (the no-op + data-disabled='' contract);
    // every other state (rest, pressed) drives the default enabled toggle.
    node: (() => {
      const disabled = currentState() === "disabled";
      return (
        <Toggle
          className="rt-reset rt-BaseButton rt-Button rt-r-size-2 rt-variant-soft"
          aria-label="Bold"
          {...(disabled ? { disabled: true } : {})}
        >
          B
        </Toggle>
      );
    })(),
  },
  {
    id: "togglegroup",
    label: "Toggle Group",
    interactive: true,
    // `?s=disabled-skip` disables the MIDDLE item so the APG roving check can prove arrows
    // SKIP over it (RovingFocusGroup filters candidateNodes to focusable items). `?s=multiple`
    // renders type=multiple (root role=group in the dist; items keep aria-pressed, NOT
    // role=radio/aria-checked) with TWO items pressed simultaneously. Every other state keeps
    // the canonical single-mode 3-enabled instance the pressed oracle pins.
    node: (() => {
      const s = currentState();
      if (s === "multiple") {
        return (
          <ToggleGroup.Root type="multiple" defaultValue={["a", "c"]} aria-label="Text formatting">
            <ToggleGroup.Item value="a">Bold</ToggleGroup.Item>
            <ToggleGroup.Item value="b">Italic</ToggleGroup.Item>
            <ToggleGroup.Item value="c">Underline</ToggleGroup.Item>
          </ToggleGroup.Root>
        );
      }
      const disableMiddle = s === "disabled-skip";
      // disabled-skip seeds value="a" (Center is the disabled middle, so it can't be the
      // selected/tab-stop item); the canonical pressed path keeps defaultValue="b" (Center
      // selected) so the existing pressed oracle + APG checks are untouched.
      const dv = disableMiddle ? "a" : "b";
      return (
        <ToggleGroup.Root type="single" defaultValue={dv} aria-label="Text alignment">
          <ToggleGroup.Item value="a">Left</ToggleGroup.Item>
          <ToggleGroup.Item value="b" disabled={disableMiddle}>Center</ToggleGroup.Item>
          <ToggleGroup.Item value="c">Right</ToggleGroup.Item>
        </ToggleGroup.Root>
      );
    })(),
  },
  {
    id: "segmentedcontrol",
    label: "Segmented Control (interactive)",
    interactive: true,
    node: (
      <SegmentedControl.Root defaultValue="inbox">
        <SegmentedControl.Item value="inbox">Inbox</SegmentedControl.Item>
        <SegmentedControl.Item value="drafts">Drafts</SegmentedControl.Item>
        <SegmentedControl.Item value="sent">Sent</SegmentedControl.Item>
      </SegmentedControl.Root>
    ),
  },
  {
    id: "checkboxgroup",
    label: "Checkbox Group (interactive)",
    interactive: true,
    node: (
      <CheckboxGroup.Root>
        <CheckboxGroup.Item value="1">Fun</CheckboxGroup.Item>
      </CheckboxGroup.Root>
    ),
  },
  {
    id: "radiocards",
    label: "Radio Cards (interactive)",
    interactive: true,
    node: (
      <RadioCards.Root defaultValue="1">
        <RadioCards.Item value="1">
          <Text weight="bold">8-core CPU</Text>
        </RadioCards.Item>
        <RadioCards.Item value="2">
          <Text weight="bold">6-core CPU</Text>
        </RadioCards.Item>
        <RadioCards.Item value="3">
          <Text weight="bold">4-core CPU</Text>
        </RadioCards.Item>
      </RadioCards.Root>
    ),
  },
  {
    id: "checkboxcards",
    label: "Checkbox Cards (interactive)",
    interactive: true,
    node: (
      <CheckboxCards.Root>
        <CheckboxCards.Item value="terms">
          <Text>Agree to Terms and Conditions</Text>
        </CheckboxCards.Item>
      </CheckboxCards.Root>
    ),
  },
  {
    id: "tabnav",
    label: "Tab Nav (interactive)",
    interactive: true,
    node: (
      <TabNav.Root>
        <TabNav.Link href="#account" active>
          Account
        </TabNav.Link>
        <TabNav.Link href="#documents">Documents</TabNav.Link>
        <TabNav.Link href="#settings">Settings</TabNav.Link>
      </TabNav.Root>
    ),
  },
  {
    id: "slider",
    label: "Slider (interactive)",
    interactive: true,
    // `?s=disabled` renders the disabled slider (aria-disabled + data-disabled on root/track/
    // range/thumb, thumb tabindex dropped). Default (rest/stepped) is the enabled single thumb.
    node: (() => {
      const disabled = currentState() === "disabled";
      return (
        <Box style={{ maxWidth: 320 }}>
          <Slider defaultValue={[40]} {...(disabled ? { disabled: true } : {})} />
        </Box>
      );
    })(),
  },
  {
    id: "accessibleicon",
    label: "Accessible Icon (interactive)",
    interactive: true,
    // The primitive cloneElements aria-hidden="true" + focusable="false" ONTO the svg
    // itself (NOT a wrapper span), then renders a VisuallyHidden label sibling. The svg
    // here is authored WITHOUT those attrs so the oracle proves upstream injects them on
    // the icon node. No interaction; the at-rest DOM is the oracle.
    node: (
      <Flex align="center">
        <AccessibleIcon label="Settings">
          <svg width="15" height="15" viewBox="0 0 15 15" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path
              fillRule="evenodd"
              clipRule="evenodd"
              fill="currentColor"
              d="M7.07.65a1.5 1.5 0 0 0-1.14 0l-.69.29-.74-.18a1.5 1.5 0 0 0-1.07.2l-.6.43-.76.05a1.5 1.5 0 0 0-.98.55l-.42.6-.7.3a1.5 1.5 0 0 0-.78.78l-.3.7-.43.6a1.5 1.5 0 0 0-.2 1.07l.18.74-.29.69a1.5 1.5 0 0 0 0 1.14l.29.69-.18.74a1.5 1.5 0 0 0 .2 1.07l.43.6.3.7c.16.36.43.63.78.78l.7.3.42.6c.24.34.6.55.98.55l.76.05.6.43c.32.23.7.3 1.07.2l.74-.18.69.29c.36.15.78.15 1.14 0l.69-.29.74.18c.37.1.75.03 1.07-.2l.6-.43.76-.05c.38 0 .74-.21.98-.55l.42-.6.7-.3a1.5 1.5 0 0 0 .78-.78l.3-.7.43-.6c.23-.32.3-.7.2-1.07l-.18-.74.29-.69a1.5 1.5 0 0 0 0-1.14l-.29-.69.18-.74a1.5 1.5 0 0 0-.2-1.07l-.43-.6-.3-.7a1.5 1.5 0 0 0-.78-.78l-.7-.3-.42-.6a1.5 1.5 0 0 0-.98-.55l-.76-.05-.6-.43a1.5 1.5 0 0 0-1.07-.2l-.74.18L7.07.65ZM7.5 10a2.5 2.5 0 1 0 0-5 2.5 2.5 0 0 0 0 5Z"
            />
          </svg>
        </AccessibleIcon>
      </Flex>
    ),
  },
  {
    id: "avatar",
    label: "Avatar (interactive)",
    interactive: true,
    // Fallback-only avatar (NO src): Radix Avatar.Image reports loading status 'error'
    // immediately, so the at-rest DOM is the FALLBACK branch — a single rt-AvatarFallback
    // span, the <img> ABSENT. The oracle pins: img absent, fallback present, accessible
    // name on the fallback, and (themes-a11y) zero axe violations on a fallback-only avatar.
    node: <Avatar fallback="A" />,
  },
  {
    id: "progress",
    label: "Progress (interactive)",
    interactive: true,
    // A single determinate bar at value=25/max=100 — the oracle target for the role=
    // progressbar + aria-valuemin/max/now/valuetext contract (and the data-state/value/
    // max wiring on root + indicator). value < max ⇒ data-state="loading"; React
    // stringifies the number 25 as the INTEGER "25" (the PureScript `show 25.0`="25.0"
    // divergence this oracle pins). No interaction; the at-rest DOM is the oracle.
    // `?s` variants exercise the value/max contract the at-rest pixel oracle never did:
    //   indeterminate (no value) → data-state=indeterminate, NO aria-valuenow/valuetext/data-value
    //   complete (value===max)   → data-state=complete on root AND indicator (strict equality)
    //   custommax (max=200,val=50) → aria-valuemax=200, aria-valuetext=25%, data-max=200
    node: (() => {
      const s = currentState();
      const inner =
        s === "indeterminate" ? <Progress /> :
        s === "complete" ? <Progress value={100} /> :
        s === "custommax" ? <Progress value={50} max={200} /> :
        <Progress value={25} />;
      return <Box style={{ maxWidth: 320 }}>{inner}</Box>;
    })(),
  },
  {
    id: "scrollarea",
    label: "Scroll Area (interactive)",
    interactive: true,
    // type="always" → the scrollbar is present at rest (no hover/scroll timing); the
    // 120px box with taller content overflows vertically; scrollbars="vertical" renders
    // exactly ONE scrollbar (no horizontal, no corner) for a deterministic anatomy:
    // Root > Viewport > content + Scrollbar(vertical) > Thumb. Thumb size/offset are px
    // (normalized to <px>); the oracle tests STRUCTURE.
    node: (
      <ScrollArea type="always" scrollbars="vertical" style={{ width: 200, height: 120 }}>
        <Box p="2" style={{ width: 160 }}>
          {Array.from({ length: 12 }, (_, i) => (
            <Text key={i} as="p" size="2">
              Line {i + 1}
            </Text>
          ))}
        </Box>
      </ScrollArea>
    ),
  },
  // ── Bare @radix-ui/react-* primitives Radix Themes ships NO component for ───────
  // (toolbar / password-toggle-field / one-time-password-field / form). These render the
  // genuine upstream primitive directly (unstyled — NO rt-* classes) so the open-state DOM
  // oracle captures the real role/data-*/aria/tabindex contract the Halogen port reproduces.
  // Some carry a `?s=<variant>` switch (read off location.search) so one interactive page can
  // expose multiple at-rest stories (toolbar vertical, otp empty) without a second id.
  {
    id: "toolbar",
    label: "Toolbar",
    interactive: true,
    // APG Toolbar: roving tabindex stamps tabindex=0 on the first focusable item and -1 on the
    // rest synchronously on mount — fully deterministic at rest. `?s=vertical` flips orientation.
    node: (() => {
      const s = currentState();
      const orientation = s === "vertical" ? "vertical" : "horizontal";
      // `?s=disabled` disables the BUTTON (New) so the roving order skips it (it gets the
      // native disabled attr + is excluded from candidateNodes — focusable={!disabled}).
      const disableButton = s === "disabled";
      return (
        <Toolbar.Root aria-label="Formatting" orientation={orientation}>
          <Toolbar.Button disabled={disableButton}>New</Toolbar.Button>
          <Toolbar.Link href="#">Edit</Toolbar.Link>
          <Toolbar.Separator />
          <Toolbar.ToggleGroup type="single" defaultValue="left" aria-label="Align">
            <Toolbar.ToggleItem value="left">L</Toolbar.ToggleItem>
            <Toolbar.ToggleItem value="center">C</Toolbar.ToggleItem>
          </Toolbar.ToggleGroup>
        </Toolbar.Root>
      );
    })(),
  },
  {
    id: "passwordtoggle",
    label: "Password Toggle Field",
    interactive: true,
    // Text Slot (Show/Hide) so the button has inner text → the auto aria-label (MutationObserver
    // + hydration timing) is SUPPRESSED; explicit input id="password" so inputId is literal (no
    // useId) and the toggle's id/aria-controls don't even need the id normalizer.
    node: (
      <Box>
        <label htmlFor="password">Password</label>
        <PasswordToggleField.Root>
          <PasswordToggleField.Input id="password" />
          <PasswordToggleField.Toggle>
            <PasswordToggleField.Slot visible="Hide" hidden="Show" />
          </PasswordToggleField.Toggle>
        </PasswordToggleField.Root>
      </Box>
    ),
  },
  {
    id: "otp",
    label: "One-Time Password Field",
    interactive: true,
    // 3-slot field; `?s=empty` renders without defaultValue. autoFocus={false} so no input is
    // focused at mount (the active element is non-deterministic; the roving tabindex 0/-1 we
    // oracle is value-derived, not focus-derived). validationType defaults to numeric.
    node: (() => {
      const s = currentState();
      const empty = s === "empty" || s === "typed";
      // `?s=alpha` exercises validationType="alpha": each slot gets inputmode=text +
      // pattern=[a-zA-Z]{1} (rejects digits). defaultValue "abc" (all alpha) at rest.
      const alpha = s === "alpha";
      return (
        <Box>
          <OneTimePasswordField.Root
            {...(empty ? {} : { defaultValue: alpha ? "abc" : "123" })}
            {...(alpha ? { validationType: "alpha" as const } : {})}
            autoFocus={false}
          >
            <OneTimePasswordField.Input />
            <OneTimePasswordField.Input />
            <OneTimePasswordField.Input />
            <OneTimePasswordField.HiddenInput />
          </OneTimePasswordField.Root>
        </Box>
      );
    })(),
  },
  {
    id: "form",
    label: "Form",
    interactive: true,
    // `?s=serverInvalid` / `?s=forceMatch` pre-seed the deterministic invalid anatomy (pure prop /
    // forceMatch render — no event, no async). The default (rest-valid / valueMissing) story is a
    // required email Control with two match Messages; valueMissing fires via the Submit click.
    node: (() => {
      const s = currentState();
      const serverInvalid = s === "serverInvalid";
      const forceMatch = s === "forceMatch";
      // `?s=multiMessage` forceMatches BOTH messages at once → aria-describedby must list
      // BOTH ids, space-joined in registration order (the multi-id describedby contract).
      const multi = s === "multiMessage";
      return (
        <Box>
          <Form.Root>
            <Form.Field name="email" serverInvalid={serverInvalid}>
              <Form.Label>Email</Form.Label>
              <Form.Control type="email" required />
              <Form.Message match="valueMissing" forceMatch={forceMatch || multi}>
                This value is missing
              </Form.Message>
              <Form.Message match="typeMismatch" forceMatch={multi}>Provide a valid email</Form.Message>
            </Form.Field>
            <Form.Submit>Submit</Form.Submit>
          </Form.Root>
        </Box>
      );
    })(),
  },
  // ── Wave-B stateless depth oracles ─────────────────────────────────────────────
  // Bare @radix-ui/react-* primitives driven into at-rest variant stories via ?s=<state>.
  // The DOM (role/aria/data-*/inline-style) is the oracle — no interaction.
  {
    id: "separatorprim",
    label: "Separator (primitive)",
    interactive: true,
    // Four combos via ?s=: hsem (horizontal+semantic) / vsem (vertical+semantic) /
    // hdec (horizontal+decorative) / vdec (vertical+decorative). The a11y contract:
    // semantic → role=separator (+ aria-orientation ONLY when vertical); decorative →
    // role=none, NO aria-orientation. data-orientation always present.
    node: (() => {
      const s = currentState();
      const orientation = s === "vsem" || s === "vdec" ? "vertical" : "horizontal";
      const decorative = s === "hdec" || s === "vdec";
      return <SeparatorPrim.Root orientation={orientation} decorative={decorative} />;
    })(),
  },
  {
    id: "aspectratioprim",
    label: "Aspect Ratio (primitive)",
    interactive: true,
    // ?s=default (ratio omitted ⇒ default 1/1 ⇒ padding-bottom:100%), ?s=wide (16/9 ⇒
    // 56.25%), ?s=tall (1/2 ⇒ 200%), ?s=styled (inner style background merge + id/aria/
    // data-* passthrough onto the INNER div + class on inner). The wrapper carries
    // data-radix-aspect-ratio-wrapper="" and the relative/padding-bottom box geometry.
    node: (() => {
      const s = currentState();
      const ratio = s === "wide" ? 16 / 9 : s === "tall" ? 1 / 2 : s === "verywide" ? 21 / 9 : undefined;
      if (s === "styled") {
        return (
          <AspectRatioPrim.Root
            ratio={16 / 9}
            id="ar-inner"
            aria-label="cover"
            data-foo="bar"
            className="my-inner"
            style={{ backgroundColor: "red" }}
          >
            <span>X</span>
          </AspectRatioPrim.Root>
        );
      }
      return (
        <AspectRatioPrim.Root {...(ratio === undefined ? {} : { ratio })}>
          <span>X</span>
        </AspectRatioPrim.Root>
      );
    })(),
  },
  {
    id: "visuallyhiddenprim",
    label: "Visually Hidden (primitive)",
    interactive: true,
    // ?s=plain (canonical clip style + text in a11y tree), ?s=props (id + aria-* + data-*
    // passthrough onto the span), ?s=stylemerge (caller style overrides one default key
    // and adds a new key — last-wins merge over VISUALLY_HIDDEN_STYLES).
    node: (() => {
      const s = currentState();
      if (s === "props") {
        return (
          <VisuallyHiddenPrim.Root id="vh-1" aria-live="polite" data-state="x">
            required
          </VisuallyHiddenPrim.Root>
        );
      }
      if (s === "stylemerge") {
        return (
          <VisuallyHiddenPrim.Root style={{ position: "fixed", color: "red" }}>
            required
          </VisuallyHiddenPrim.Root>
        );
      }
      return <VisuallyHiddenPrim.Root>required</VisuallyHiddenPrim.Root>;
    })(),
  },
  {
    id: "labelprim",
    label: "Label (primitive)",
    interactive: true,
    // for-association (htmlFor="email") + arbitrary prop passthrough (id / data-* /
    // aria-describedby / title) onto the <label>. The associated <input id="email">
    // makes the for→control linkage structurally present. The onMouseDown multi-click
    // text-selection guard is a browser-selection side effect (not DOM-observable), so
    // it is tracked as a residual, not asserted here.
    node: (
      <div>
        <LabelPrim.Root
          htmlFor="email"
          id="email-label"
          data-foo="bar"
          aria-describedby="hint"
          title="Your email"
        >
          Email
        </LabelPrim.Root>
        <input id="email" />
      </div>
    ),
  },
  // The composed demo — the "looks like a finished product" target.
  {
    id: "signin",
    label: "Sign-in card",
    node: (
      <Box style={{ maxWidth: 400 }}>
        <Card size="4">
          <Heading as="h3" size="6" trim="start" mb="5">
            Sign in
          </Heading>
          <Box mb="5">
            <Flex direction="column" gap="1">
              <Text as="label" size="2" weight="medium">
                Email address
              </Text>
              <TextField.Root placeholder="you@example.com" />
            </Flex>
          </Box>
          <Box mb="5">
            <Flex direction="column" gap="1">
              <Flex justify="between">
                <Text as="label" size="2" weight="medium">
                  Password
                </Text>
                <Text size="2">
                  <a href="#">Forgot password?</a>
                </Text>
              </Flex>
              <TextField.Root placeholder="Enter your password" />
            </Flex>
          </Box>
          <Flex align="center" gap="2" mb="5">
            <Text as="label" size="2">
              <Flex gap="2" align="center">
                <Checkbox defaultChecked /> Remember me
              </Flex>
            </Text>
          </Flex>
          <Flex justify="end" gap="3">
            <Button variant="soft" color="gray">
              Create account
            </Button>
            <Button>Sign in</Button>
          </Flex>
        </Card>
      </Box>
    ),
  },
  // ── Wave-C: Themes.Separator WRAPPER depth oracle (distinct from the primitive) ──
  // The rt-Separator themes wrapper (NOT the bare primitive) has its own contract:
  //   * decorative defaults to TRUE → role is OMITTED ENTIRELY (role={undefined}),
  //     distinct from the primitive's role="none";
  //   * color renders as data-accent-color (default "gray");
  //   * size renders the rt-r-size-N class (default rt-r-size-1);
  //   * orientation is class-only (rt-r-orientation-*), NO data-orientation.
  // ?s= drives: default (decorative gray size1) / semantic (role=separator) /
  // size4 (rt-r-size-4) / accent (data-accent-color=cyan) / vertical (orientation class).
  {
    id: "separatorthemes",
    label: "Separator (themes)",
    interactive: true,
    node: (() => {
      const s = currentState();
      if (s === "semantic") return <Separator decorative={false} />;
      if (s === "size4") return <Separator size="4" />;
      if (s === "accent") return <Separator color="cyan" />;
      if (s === "vertical") return <Separator orientation="vertical" />;
      return <Separator />;
    })(),
  },
];

function currentId(): string {
  const m = location.search.match(/[?&]c=([^&]+)/);
  return m ? decodeURIComponent(m[1]) : "";
}

// The `?s=<state>` value — lets one interactive page expose multiple at-rest variant stories
// (toolbar vertical, otp empty, form serverInvalid/forceMatch) keyed off the capture state name,
// without minting a second page id. Drivers that only interact (no variant) ignore this.
function currentState(): string {
  const m = location.search.match(/[?&]s=([^&]+)/);
  return m ? decodeURIComponent(m[1]) : "";
}

function Index() {
  return (
    <Box p="6" style={{ maxWidth: 900, margin: "0 auto" }}>
      <Heading size="7" mb="1">
        Radix Themes 3.3.0 — golden source
      </Heading>
      <Text as="p" color="gray" mb="5">
        Upstream render. Each card is the authoritative target the Halogen port is
        pixel-diffed against. Click a title to see it isolated (the Playwright page).
      </Text>
      <Flex direction="column" gap="4">
        {PAGES.map((p) => (
          <Card key={p.id + (p.interactive ? "-i" : "")} size="2">
            <Heading size="2" mb="3" color="gray">
              <a href={`?c=${p.id}`} style={{ color: "inherit", textDecoration: "none" }}>
                {p.label}
              </a>
            </Heading>
            {p.node}
          </Card>
        ))}
      </Flex>
    </Box>
  );
}

const id = currentId();
// Open-state DOM oracle path: ?c=<id>&s=<state> selects the `interactive` page for that id
// (a stateful story driven into <state>), keeping the plain ?c=<id> pixel/a11y path on the
// canonical at-rest page above. For ids that only have an interactive page (the four bare
// primitives), either path resolves to it.
const openState = /[?&]s=/.test(location.search);
const page =
  (openState ? PAGES.find((p) => p.id === id && p.interactive) : undefined) ??
  PAGES.find((p) => p.id === id);
const content = page ? <Box p="6">{page.node}</Box> : <Index />;

createRoot(document.getElementById("root")!).render(
  <Theme
    accentColor="indigo"
    grayColor="slate"
    radius="medium"
    appearance="light"
    style={{ ["--default-font-family" as string]: "'Inter Variable', sans-serif" }}
  >
    {content}
  </Theme>,
);
